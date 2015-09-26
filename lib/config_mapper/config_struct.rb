module ConfigMapper

  # A configuration container
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
      # @param type [Symbol] name of type-coercion method
      # @options options [String] :default (nil) default value
      # @yield type-coercion block
      #
      def attribute(name, type = nil, options = {}, &coerce_block)

        name = name.to_sym

        # Handle optional "type" argument
        if options.empty? && type.kind_of?(Hash)
          options = type
          type = nil
        end
        if type
          coerce_block = method(type)
        end

        if options.key?(:default)
          defaults[name] = options.fetch(:default).freeze
        else
          required_attributes << name
        end

        attr_accessor(name)

        if coerce_block
          define_method("#{name}=") do |arg|
            instance_variable_set("@#{name}", coerce_block.call(arg))
          end
        end

      end

      # Defines a sub-component.
      #
      def component(name, component_class = ConfigStruct, &block)
        name = name.to_sym
        if block
          component_class = Class.new(component_class, &block)
        end
        components[name] = component_class
        attr_reader name
      end

      def required_attributes
        @required_attributes ||= []
      end

      def defaults
        @defaults ||= {}
      end

      def components
        @components ||= {}
      end

    end

    def initialize
      self.class.defaults.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
      self.class.components.each do |name, component_class|
        instance_variable_set("@#{name}", component_class.new)
      end
    end

    def undefined_attributes
      result = self.class.required_attributes.reject { |name|
        instance_variable_defined?("@#{name}")
      }.map(&:to_s)
      components.each do |component_name, value|
        next unless value.respond_to?(:undefined_attributes)
        result += value.undefined_attributes.map do |name|
          "#{component_name}.#{name}"
        end
      end
      result
    end

    private

    def components
      {}.tap do |result|
        self.class.components.each do |name, _|
          result[name] = instance_variable_get("@#{name}")
        end
      end
    end

  end

end
