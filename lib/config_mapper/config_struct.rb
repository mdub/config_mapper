module ConfigMapper

  # A configuration container
  #
  class ConfigStruct

    def self.property(name)
      attr_accessor(name)
    end

  end

end
