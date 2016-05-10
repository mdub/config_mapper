require "forwardable"

module ConfigMapper

  class ConfigDict

    def initialize(entry_type, key_type = nil)
      @entry_type = entry_type
      @key_type = key_type
      @entries = {}
    end

    def [](key)
      key = @key_type.call(key) if @key_type
      @entries[key] ||= @entry_type.call
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
