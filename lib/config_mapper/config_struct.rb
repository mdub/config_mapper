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
      def property(name, type = nil, options = {}, &coerce_block)

        # Handle optional "type" argument
        if options.empty? && type.kind_of?(Hash)
          options = type
          type = nil
        end
        if type
          coerce_block = method(type)
        end

        defaults[name] = options[:default].freeze

        attr_accessor(name)

        if coerce_block
          define_method("#{name}=") do |arg|
            instance_variable_set("@#{name}", coerce_block.call(arg))
          end
        end

      end

      def defaults
        @defaults ||= {}
      end

      # Defines a sub-component.
      #
      def component(name, &block)
        components[name] = Class.new(ConfigStruct, &block)
        attr_reader name
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

  end

end
