module ConfigMapper

  # Wrap an object to make it look more like a Hash.
  #
  class ObjectTarget

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
