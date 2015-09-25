module ConfigMapper

  # A configuration container
  #
  class ConfigStruct

    def self.property(name, type = nil, options = {}, &coerce_block)

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

    def self.defaults
      @defaults ||= {}
    end

    def initialize
      self.class.defaults.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
    end

  end

end
