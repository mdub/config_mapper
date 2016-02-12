require "config_mapper/abstract_target"

module ConfigMapper

  # Configuration proxy for an Object.
  #
  class ObjectTarget < AbstractTarget

    def initialize(object)
      @object = object
    end

    def path(key)
      ".#{key}"
    end

    def get(key)
      @object.public_send(key)
    end

    def set(key, value)
      @object.public_send("#{key}=", value)
    end

  end

end
