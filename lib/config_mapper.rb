require "config_mapper/hash_target"
require "config_mapper/object_target"

# Supports marshalling of plain-old data (e.g. loaded from
# YAML files) onto strongly-typed objects.
#
module ConfigMapper

  class << self

    # Attempt to set attributes on a target object.
    #
    # For simple, scalar values, set the attribute by calling the
    # named writer-method on the target object.
    #
    # For Hash values, set attributes of the named sub-component.
    #
    # @return [Hash] exceptions encountered
    #
    def set(data, target_object)
      target = wrap_target(target_object)
      AttributeMapping.new(data, target).apply
    end

    private

    def wrap_target(target_object)
      if target_object.is_a?(Hash)
        HashTarget.new(target_object)
      else
        ObjectTarget.new(target_object)
      end
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
