require "config_mapper/hash_target"
require "config_mapper/object_target"

# Supports marshalling of plain-old data (e.g. loaded from
# YAML files) onto strongly-typed objects.
#
module ConfigMapper

  class << self

    def configure(target)
      if target.is_a?(Hash)
        HashTarget.new(target)
      else
        ObjectTarget.new(target)
      end
    end

    # Configure a target object.
    #
    # For simple, scalar values, set the attribute by calling the
    # named writer-method on the target object.
    #
    # For Hash values, set attributes of the named sub-component.
    #
    # @deprecated Prefer ConfigMapper.configure(object).with(data)
    #
    # @param data configuration data
    # @param [Object, Hash] target_object object to configure
    #
    # @return [Hash] exceptions encountered
    #
    def set(data, target_object)
      configure(target_object).with(data)
    end

  end

end
