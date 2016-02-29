require "config_mapper/config_dict"
require "config_mapper/dict_mapper"
require "config_mapper/object_mapper"

# Supports marshalling of plain-old data (e.g. loaded from
# YAML files) onto strongly-typed objects.
#
module ConfigMapper

  class << self

    # Set attributes of a target object based on configuration data.
    #
    # For simple, scalar values, set the attribute by calling the
    # named writer-method on the target object.
    #
    # For Hash values, set attributes of the named sub-component.
    #
    # @param data configuration data
    # @param [Object, Hash] target the object to configure
    #
    # @return [Hash] exceptions encountered
    #
    def configure_with(data, target)
      mapper_for(target).configure_with(data)
    end

    alias_method :set, :configure_with

    def mapper_for(target)
      if target.is_a?(Hash) || target.is_a?(ConfigMapper::ConfigDict)
        DictMapper.new(target)
      else
        ObjectMapper.new(target)
      end
    end

  end

end
