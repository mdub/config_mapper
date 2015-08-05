module ConfigMapper

  # Wrap an object to make it look more like a Hash.
  #
  class ObjectAsHash

    def self.[](target)
      if target.is_a?(Hash)
        target
      else
        ObjectAsHash.new(target)
      end
    end

    def initialize(target)
      @target = target
    end

    def [](key)
      @target.public_send(key)
    end

    def []=(key, value)
      @target.public_send("#{key}=", value)
    end

  end

end
