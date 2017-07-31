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
      @entries[key] ||= @entry_factory.new
    end

    def to_h
      {}.tap do |result|
        @entries.each do |key, value|
          result[key] = value.to_h
        end
      end
    end

    def config_errors
      {}.tap do |errors|
        each do |key, value|
          prefix = "[#{key.inspect}]"
          next unless value.respond_to?(:config_errors)
          value.config_errors.each do |path, path_errors|
            errors["#{prefix}#{path}"] = path_errors
          end
        end
      end
    end

    extend Forwardable

    def_delegators :@entries, :each, :empty?, :key?, :keys, :map, :size

    include Enumerable

    class Factory

      def initialize(entry_factory, key_validator)
        @entry_factory = entry_factory
        @key_validator = key_validator
      end

      attr_reader :entry_factory
      attr_reader :key_validator

      def new
        ConfigDict.new(@entry_factory, @key_validator)
      end

      def config_doc
        return {} unless entry_factory.respond_to?(:config_doc)
        {}.tap do |result|
          entry_factory.config_doc.each do |path, doc|
            result["[X]#{path}"] = doc
          end
        end
      end

    end

  end

end
