module ConfigMapper

  # Something that accepts configuration.
  #
  class Mapper

    # Map configuration data onto the target.
    #
    # @return [Hash] exceptions encountered
    #
    def configure_with(data)
      errors = {}
      if Array === data
        data = data.each_with_index.to_a.map(&:reverse).to_h
      end
      data.each do |key, value|
        configure_attribute(key, value, errors)
      end
      errors
    end

    private

    # Set a single attribute.
    #
    def configure_attribute(key, value, errors)
      attribute_path = path(key)
      if can_set?(key)
        set(key, value)
      else
        nested_errors = ConfigMapper.configure_with(value, get(key))
        nested_errors.each do |nested_path, error|
          errors["#{attribute_path}#{nested_path}"] = error
        end
      end
    rescue NoMethodError, ArgumentError => e
      errors[attribute_path] = e
    end

  end

end
