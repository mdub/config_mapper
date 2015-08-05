require "config_mapper/attribute_sink"

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
    mapper = AttributeSink.new(target)
    mapper.set_attributes(data)
    mapper.errors
  end

end
