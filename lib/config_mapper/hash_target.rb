module ConfigMapper

  # Wrap an object to make it look more like a Hash.
  #
  class HashTarget

    def initialize(hash)
      @hash = hash
    end

    def path(key)
      "[#{key.inspect}]"
    end

    def get(key)
      @hash[key]
    end

    def set(key, value)
      @hash[key] = value
    end

  end

end
