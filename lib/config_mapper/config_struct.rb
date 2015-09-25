module ConfigMapper

  # A configuration container
  #
  class ConfigStruct

    def self.property(name, &coerce_block)
      attr_accessor(name)
      if coerce_block
        define_method("#{name}=") do |arg|
          instance_variable_set("@#{name}", coerce_block.call(arg))
        end
      end
    end

  end

end
