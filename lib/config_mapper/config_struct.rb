require "config_mapper"
require "config_mapper/config_dict"

module ConfigMapper

  # A set of configurable attributes.
  #
  class ConfigStruct

    class << self

      # Defines reader and writer methods for the specified attribute.
      #
      # A `:default` value may be specified; otherwise, the attribute is
      # considered mandatory.
      #
      # If a block is provided, it will invoked in the writer-method to
      # validate the argument.
      #
      # @param name [Symbol] attribute name
      # @param default default value
      # @yield type-coercion block
      #
      def attribute(name, type = nil, default: :no_default, &type_block)
        name = name.to_sym
        required = true
        default_value = nil
        type ||= type_block
        unless default == :no_default
          default_value = default.freeze
          required = false if default_value.nil?
        end
        attribute_initializers[name] = proc { default_value }
        required_attributes << name if required
        attr_reader(name)
        define_method("#{name}=") do |value|
          if value.nil?
            raise NoValueProvided if required
          else
            value = type.call(value) if type
          end
          instance_variable_set("@#{name}", value)
        end
      end

      # Defines a sub-component.
      #
      # If a block is be provided, it will be `class_eval`ed to define the
      # sub-components class.
      #
      # @param name [Symbol] component name
      # @param type [Class] component base-class
      #
      def component(name, type: ConfigStruct, &block)
        name = name.to_sym
        declared_components << name
        type = Class.new(type, &block) if block
        type = type.method(:new) if type.respond_to?(:new)
        attribute_initializers[name] = type
        attr_reader name
      end

      # Defines an associative array of sub-components.
      #
      # If a block is be provided, it will be `class_eval`ed to define the
      # sub-components class.
      #
      # @param name [Symbol] dictionary attribute name
      # @param type [Class] base-class for component values
      # @param key_type [Proc] function used to validate keys
      #
      def component_dict(name, type: ConfigStruct, key_type: nil, &block)
        name = name.to_sym
        declared_component_dicts << name
        type = Class.new(type, &block) if block
        type = type.method(:new) if type.respond_to?(:new)
        key_type = key_type.method(:new) if key_type.respond_to?(:new)
        attribute_initializers[name] = lambda do
          ConfigDict.new(type, key_type)
        end
        attr_reader name
      end

      def required_attributes
        @required_attributes ||= []
      end

      def attribute_initializers
        @attribute_initializers ||= {}
      end

      def declared_components
        @declared_components ||= []
      end

      def declared_component_dicts
        @declared_component_dicts ||= []
      end

      def for_all(attribute, &action)
        ancestors.each do |klass|
          next unless klass.respond_to?(attribute)
          klass.public_send(attribute).each(&action)
        end
      end

    end

    def initialize
      self.class.for_all(:attribute_initializers) do |name, initializer|
        instance_variable_set("@#{name}", initializer.call)
      end
    end

    def immediate_config_errors
      missing_required_attribute_errors
    end

    def config_errors
      immediate_config_errors.merge(component_config_errors)
    end

    # Configure with data.
    #
    # @param attribute_values [Hash] attribute values
    # @return [Hash] errors encountered, keyed by attribute path
    #
    def configure_with(attribute_values)
      errors = ConfigMapper.configure_with(attribute_values, self)
      config_errors.merge(errors)
    end

    # Return the configuration as a Hash.
    #
    # @return [Hash] serializable config data
    #
    def to_h
      {}.tap do |result|
        self.class.for_all(:attribute_initializers) do |attr_name, _|
          value = send(attr_name)
          if value && value.respond_to?(:to_h) && !value.is_a?(Array)
            value = value.to_h
          end
          result[attr_name.to_s] = value
        end
      end
    end

    private

    def components
      {}.tap do |result|
        self.class.for_all(:declared_components) do |name|
          result[".#{name}"] = instance_variable_get("@#{name}")
        end
        self.class.for_all(:declared_component_dicts) do |name|
          instance_variable_get("@#{name}").each do |key, value|
            result[".#{name}[#{key.inspect}]"] = value
          end
        end
      end
    end

    class NoValueProvided < ArgumentError

      def initialize
        super("no value provided")
      end

    end

    def missing_required_attribute_errors
      {}.tap do |errors|
        self.class.for_all(:required_attributes) do |name|
          if instance_variable_get("@#{name}").nil?
            errors[".#{name}"] = NoValueProvided.new
          end
        end
      end
    end

    def component_config_errors
      {}.tap do |errors|
        components.each do |component_name, component_value|
          next unless component_value.respond_to?(:config_errors)
          component_value.config_errors.each do |key, value|
            errors["#{component_name}#{key}"] = value
          end
        end
      end
    end

  end

end
