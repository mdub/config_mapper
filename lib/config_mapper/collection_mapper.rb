# frozen_string_literal: true

require "config_mapper/mapper"

module ConfigMapper

  # Configuration proxy for a collection (e.g. Hash, Array, ConfigDict)
  #
  class CollectionMapper < Mapper

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

    def can_set?(_key)
      @hash.respond_to?("[]=")
    end

  end

end
