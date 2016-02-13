require "config_mapper/target"

module ConfigMapper

  # Configuration proxy for an Object.
  #
  class ObjectTarget < Target

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
