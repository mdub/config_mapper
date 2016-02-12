module ConfigMapper

  # Wrap an object to make it look more like a Hash.
  #
  class AbstractTarget

    def configure_with(data)
      AttributeMapping.new(data, self).apply
    end

  end

  # Sets attributes on an object, collecting errors
  #
  class AttributeMapping

    def initialize(data, target)
      @data = data
      @target = target
      @errors = {}
    end

    attr_reader :data
    attr_reader :target
    attr_reader :errors

    # Set multiple attributes from a Hash.
    #
    def apply
      data.each do |key, value|
        set_attribute(key, value)
      end
      errors
    end

    private

    # Set a single attribute.
    #
    def set_attribute(key, value)
      attribute_path = target.path(key)
      if value.is_a?(Hash) && !target.get(key).nil?
        nested_errors = ConfigMapper.set(value, target.get(key))
        nested_errors.each do |nested_path, error|
          errors["#{attribute_path}#{nested_path}"] = error
        end
      else
        target.set(key, value)
      end
    rescue NoMethodError, ArgumentError => e
      errors[attribute_path] = e
    end

  end

end
