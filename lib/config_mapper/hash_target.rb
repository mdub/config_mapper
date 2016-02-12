require "config_mapper/abstract_target"

module ConfigMapper

  # Wrap an object to make it look more like a Hash.
  #
  class HashTarget < AbstractTarget

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
