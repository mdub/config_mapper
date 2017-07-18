require "forwardable"

module ConfigMapper

  class ConfigDict

    def initialize(entry_factory, key_validator = nil)
      @entry_factory = entry_factory
      @key_validator = key_validator
      @entries = {}
    end

    def [](key)
      key = @key_validator.call(key) if @key_validator
      @entries[key] ||= @entry_factory.call
    end

    def to_h
      {}.tap do |result|
        @entries.each do |key, value|
          result[key] = value.to_h
        end
      end
    end

    extend Forwardable

    def_delegators :@entries, :each, :empty?, :key?, :keys, :map, :size

    include Enumerable

  end

end
