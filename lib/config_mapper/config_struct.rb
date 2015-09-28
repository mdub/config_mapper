require "forwardable"

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
      # @options options [String] :default (nil) default value
      # @yield type-coercion block
      #
      def attribute(name, options = {}, &coerce_block)
        name = name.to_sym
        if options.key?(:default)
          default_value = options.fetch(:default).freeze
          attribute_initializers[name] = proc { default_value }
        else
          required_attributes << name
        end
        attr_reader(name)
        if coerce_block
          define_method("#{name}=") do |arg|
            instance_variable_set("@#{name}", coerce_block.call(arg))
          end
        else
          attr_writer(name)
        end
      end

      # Defines a sub-component.
      #
      def component(name, factory = ConfigStruct, &block)
        name = name.to_sym
        declared_components << name
        factory = Class.new(factory, &block) if block
        factory = factory.method(:new) if factory.respond_to?(:new)
        attribute_initializers[name] = factory
        attr_reader name
      end

      # Defines an associative array of sub-components.
      #
      def component_map(name, factory = ConfigStruct, &block)
        name = name.to_sym
        declared_component_maps << name
        factory = Class.new(factory, &block) if block
        factory = factory.method(:new) if factory.respond_to?(:new)
        attribute_initializers[name] = lambda do
          ConfigDict.new(&factory)
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

      def declared_component_maps
        @declared_component_maps ||= []
      end

    end

    def initialize
      self.class.attribute_initializers.each do |name, initializer|
        instance_variable_set("@#{name}", initializer.call)
      end
    end

    def undefined_attributes
      result = self.class.required_attributes.map(&:to_s).reject do |name|
        instance_variable_defined?("@#{name}")
      end
      components.each do |component_name, value|
        if value.respond_to?(:undefined_attributes)
          result += value.undefined_attributes.map do |name|
            "#{component_name}.#{name}"
          end
        end
      end
      result
    end

    private

    def components
      {}.tap do |result|
        self.class.declared_components.each do |name|
          result[name] = instance_variable_get("@#{name}")
        end
        self.class.declared_component_maps.each do |name|
          instance_variable_get("@#{name}").each do |key, value|
            result["#{name}[#{key.inspect}]"] = value
          end
        end
      end
    end

  end

  class ConfigDict

    def initialize(&entry_factory)
      @entry_factory = entry_factory
      @entries = {}
    end

    def [](key)
      @entries[key] ||= @entry_factory.call
    end

    extend Forwardable

    def_delegators :@entries, :each, :empty?

    include Enumerable

  end

end
