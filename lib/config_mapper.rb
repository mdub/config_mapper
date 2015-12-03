require "config_mapper/object_as_hash"

# Supports marshalling of plain-old data (e.g. loaded from
# YAML files) onto strongly-typed objects.
#
module ConfigMapper

  # Attempt to set attributes on a target object.
  #
  # For simple, scalar values, set the attribute by calling the
  # named writer-method on the target object.
  #
  # For Hash values, set attributes of the named sub-component.
  #
  # @return [Hash] exceptions encountered
  #
  def self.set(data, target)
    target = ObjectAsHash[target]
    AttributeMapping.new(data, target).apply
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
      target_name = if target.is_a?(ObjectAsHash)
        ".#{key}"
      else
        "[#{key.inspect}]"
      end
      if value.is_a?(Hash) && !target[key].nil?
        nested_errors = ConfigMapper.set(value, target[key])
        nested_errors.each do |nested_key, error|
          errors["#{target_name}#{nested_key}"] = error
        end
      else
        target[key] = value
      end
    rescue NoMethodError, ArgumentError => e
      errors[target_name] = e
    end

  end

end
