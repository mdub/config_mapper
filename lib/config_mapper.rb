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
      wrap_target(target_object).configure_with(data)
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

end
