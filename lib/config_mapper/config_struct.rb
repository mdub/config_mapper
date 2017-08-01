require "config_mapper"
require "config_mapper/config_dict"
require "config_mapper/factory"
require "config_mapper/validator"

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
      def attribute(name, type = nil, default: :no_default, description: nil, &type_block)

        attribute = attribute!(name)
        attribute.description = description

        if default == :no_default
          attribute.required = true
        else
          attribute.default = default.freeze
        end

        attribute.validator = Validator.resolve(type || type_block)

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
      def component(name, type: ConfigStruct, description: nil, &block)
        type = Class.new(type, &block) if block
        attribute = attribute!(name)
        attribute.description = description
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
      def component_dict(name, type: ConfigStruct, key_type: nil, description: nil, &block)
        type = Class.new(type, &block) if block
        component(name, type: ConfigDict::Factory.new(type, key_type), description: description)
      end

      # Generate documentation, as Ruby data.
      #
      # Returns an entry for each configurable path, detailing
      # `description`, `type`, and `default`.
      #
      # @return [Hash] documentation, keyed by path
      #
      def config_doc
        each_attribute.sort_by(&:name).map(&:config_doc).inject({}, :merge)
      end

      def attributes
        attributes_by_name.values
      end

      def each_attribute(&action)
        return enum_for(:each_attribute) unless action
        ancestors.each do |klass|
          next unless klass.respond_to?(:attributes)
          klass.attributes.each(&action)
        end
      end

      private

      def attributes_by_name
        @attributes_by_name ||= {}
      end

      def attribute!(name)
        attr_reader(name)
        attributes_by_name[name] ||= Attribute.new(name)
      end

    end

    def initialize
      self.class.each_attribute do |attribute|
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
        self.class.each_attribute do |attribute|
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
        self.class.each_attribute do |a|
          next unless a.factory
          result[".#{a.name}"] = instance_variable_get("@#{a.name}")
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
        self.class.each_attribute do |a|
          if a.required && instance_variable_get("@#{a.name}").nil?
            errors[".#{a.name}"] = NoValueProvided.new
          end
        end
      end
    end

    def component_config_errors
      {}.tap do |errors|
        components.each do |component_path, component_value|
          next unless component_value.respond_to?(:config_errors)
          component_value.config_errors.each do |path, value|
            errors["#{component_path}#{path}"] = value
          end
        end
      end
    end

    class Attribute

      def initialize(name)
        @name = name.to_sym
      end

      attr_reader :name

      attr_accessor :description
      attr_accessor :factory
      attr_accessor :validator
      attr_accessor :default
      attr_accessor :required

      def initial_value
        return factory.new if factory
        default
      end

      def factory=(arg)
        @factory = Factory.resolve(arg)
      end

      def config_doc
        self_doc.merge(type_doc)
      end

      private

      def self_doc
        {
          ".#{name}" => {}.tap do |doc|
            doc["description"] = description if description
            doc["default"] = default if default
            doc["type"] = String(validator.name) if validator.respond_to?(:name)
          end
        }
      end

      def type_doc
        return {} unless factory.respond_to?(:config_doc)
        factory.config_doc.each_with_object({}) do |(path, doc), result|
          result[".#{name}#{path}"] = doc
        end
      end

    end

  end

end
