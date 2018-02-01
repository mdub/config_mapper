require 'config_mapper'
require 'config_mapper/config_struct'
require "config_mapper/factory"
require "config_mapper/validator"
require "forwardable"

module ConfigMapper
  class ConfigList

    class Factory

      def initialize(entry_factory)
        @entry_factory = ConfigMapper::Factory.resolve(entry_factory)
      end

      attr_reader :entry_factory

      def new
        ConfigList.new(@entry_factory)
      end

      def config_doc
        return {} unless entry_factory.respond_to?(:config_doc)
        {}.tap do |result|
          entry_factory.config_doc.each do |path, doc|
            result["[N]#{path}"] = doc
          end
        end
      end

    end

    def initialize(entry_factory)
      @entry_factory = entry_factory
      @entries = []
    end

    def [](index)
      @entries[index] ||= @entry_factory.new
    end

    def to_a
      map do |element|
        case
          when element.respond_to?(:to_h); element.to_h
          when element.respond_to?(:to_a); element.to_a
          else element
        end
      end
    end

    def config_errors
      {}.tap do |errors|
        each_with_index do |element, index|
          next unless element.respond_to?(:config_errors)
          prefix = "[#{index}]"
          element.config_errors.each do |path, path_errors|
            errors["#{prefix}#{path}"] = path_errors
          end
        end
      end
    end

    extend Forwardable

    def_delegators :@entries, :each, :each_with_index, :empty?, :map, :size

    include Enumerable

  end
end

