require "config_mapper/target"

module ConfigMapper

  # Configuration proxy for a Hash.
  #
  class HashTarget < Target

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
