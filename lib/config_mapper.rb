# Supports marshalling of plain-old data (e.g. loaded from
# YAML files) onto strongly-typed objects.
#
class ConfigMapper

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
    mapper = new(target)
    mapper.set_attributes(data)
    mapper.errors
  end

  def initialize(target, errors = {})
    @target = target
    @errors = errors
  end

  attr_reader :target
  attr_reader :errors

  # Set multiple attributes from a Hash.
  #
  def set_attributes(data)
    data.each do |key, value|
      set_attribute(key, value)
    end
  end

  private

  # Set a single attribute.
  #
  def set_attribute(key, value)
    if value.is_a?(Hash)
      set_nested(key, value)
    else
      target.public_send("#{key}=", value)
    end
  rescue NoMethodError, ArgumentError => e
    errors[key] = e
  end

  def set_nested(key, value)
    nested_target = target.public_send(key)
    nested_errors = ErrorProxy.new(errors, "#{key}.")
    nested_mapper = self.class.new(nested_target, nested_errors)
    nested_mapper.set_attributes(value)
  end

  # Wraps a Hash of errors, injecting prefixes
  #
  class ErrorProxy

    def initialize(errors, prefix)
      @errors = errors
      @prefix = prefix
    end

    def []=(key, value)
      errors[prefix + key] = value
    end

    private

    attr_reader :errors
    attr_reader :prefix

  end

end
