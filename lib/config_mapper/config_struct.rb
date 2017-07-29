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
        attribute = attribute!(name)

        if default == :no_default
          attribute.required = true
        else
          attribute.default = default.freeze
        end

        attribute.validator = resolve_validator(type || type_block)

        define_method("#{attribute.name}=") do |value|
          if value.nil?
            raise NoValueProvided if attribute.required
          else
            value = attribute.validator.call(value) if attribute.validator
          end
          instance_variable_set("@#{attribute.name}", value)
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
        attribute = attribute!(name)
        declared_components << attribute.name
        type = Class.new(type, &block) if block
        type = type.method(:new) if type.respond_to?(:new)
        attribute.factory = type
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
        attribute = attribute!(name)
        declared_component_dicts << attribute.name
        type = Class.new(type, &block) if block
        attribute.factory = lambda do
          ConfigDict.new(type.method(:new), resolve_validator(key_type))
        end
      end

      # Generate documentation, as Ruby data.
      #
      # Returns an entry for each configurable path, detailing
      # `description`, `type`, and `default`.
      #
      # @return [Hash] documentation, keyed by path
      #
      def documentation
        {}.tap do |doc|
          for_all(:attributes) do |attribute|
            doc[".#{attribute.name}"] = attribute.documentation
          end
        end
      end

      def attributes_by_name
        @attributes_by_name ||= {}
      end

      def attribute!(name)
        attr_reader(name)
        attributes_by_name[name] ||= Attribute.new(name)
      end

      def attributes
        attributes_by_name.values
      end

      def required_attributes
        attributes.select(&:required).map(&:name)
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

      def resolve_validator(validator)
        return validator if validator.respond_to?(:call)
        if validator.respond_to?(:name)
          # looks like a primitive class -- find the corresponding coercion method
          return Kernel.method(validator.name)
        end
        validator
      end

    end

    def initialize
      self.class.for_all(:attributes) do |attribute|
        instance_variable_set("@#{attribute.name}", attribute.initial_value)
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
        self.class.for_all(:attributes) do |attribute|
          value = send(attribute.name)
          if value && value.respond_to?(:to_h) && !value.is_a?(Array)
            value = value.to_h
          end
          result[attribute.name.to_s] = value
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

    class Attribute

      def initialize(name)
        @name = name.to_sym
      end

      attr_reader :name

      attr_accessor :factory
      attr_accessor :validator
      attr_accessor :default
      attr_accessor :required

      def initial_value
        return factory.call if factory
        default
      end

      def documentation
        {}.tap do |doc|
          if default
            doc["default"] = default
          end
          if validator.respond_to?(:name)
            doc["type"] = String(validator.name)
          end
        end
      end

    end

  end

end
