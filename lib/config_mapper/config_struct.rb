module ConfigMapper

  # A configuration container
  #
  class ConfigStruct

    def self.property(name, options = {}, &coerce_block)

      attr_accessor(name)

      defaults[name] = options[:default]

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
