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

    extend Forwardable

    def_delegators :@entries, :each, :empty?, :keys, :map, :size

    include Enumerable

  end

end
