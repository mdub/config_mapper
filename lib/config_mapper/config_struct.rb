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
      # @options options [String] :default (nil) default value
      # @yield type-coercion block
      #
      def attribute(name, options = {})
        name = name.to_sym
        required = true
        if options.key?(:default)
          default_value = options.fetch(:default).freeze
          required = false if default_value.nil?
          attribute_initializers[name] = proc { default_value }
        end
        required_attributes << name if required
        attr_reader(name)
        define_method("#{name}=") do |value|
          value = yield(value) if block_given?
          instance_variable_set("@#{name}", value)
        end
      end

      # Defines a sub-component.
      #
      # If a block is be provided, it will be `class_eval`ed to define the
      # sub-components class.
      #
      # @param name [Symbol] component name
      # @options options [String] :type (ConfigMapper::ConfigStruct)
      #   component base-class
      #
      def component(name, options = {}, &block)
        name = name.to_sym
        declared_components << name
        type = options.fetch(:type, ConfigStruct)
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
      # @options options [Proc] :key_type
      #   function used to validate keys
      # @options options [String] :type (ConfigMapper::ConfigStruct)
      #   base-class for sub-component values
      #
      def component_dict(name, options = {}, &block)
        name = name.to_sym
        declared_component_dicts << name
        type = options.fetch(:type, ConfigStruct)
        type = Class.new(type, &block) if block
        type = type.method(:new) if type.respond_to?(:new)
        key_type = options[:key_type]
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

    end

    def initialize
      self.class.attribute_initializers.each do |name, initializer|
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

    private

    def components
      {}.tap do |result|
        self.class.declared_components.each do |name|
          result[".#{name}"] = instance_variable_get("@#{name}")
        end
        self.class.declared_component_dicts.each do |name|
          instance_variable_get("@#{name}").each do |key, value|
            result[".#{name}[#{key.inspect}]"] = value
          end
        end
      end
    end

    class AttributeNotSet < StandardError

      def initialize
        super("no value provided")
      end

    end

    def missing_required_attribute_errors
      {}.tap do |errors|
        self.class.required_attributes.each do |name|
          if instance_variable_get("@#{name}").nil?
            errors[".#{name}"] = AttributeNotSet.new
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
