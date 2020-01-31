# frozen_string_literal: true

require "config_mapper/mapper"

module ConfigMapper

  # Configuration proxy for an Object.
  #
  class ObjectMapper < Mapper

    def initialize(object)
      @object = object
    end

    def path(key)
      ".#{key}"
    end

    def get(key)
      @object.public_send(key.to_s)
    end

    def set(key, value)
      @object.public_send("#{key}=", value)
    end

    def can_set?(key)
      @object.respond_to?("#{key}=")
    end

  end

end
