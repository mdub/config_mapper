module ConfigMapper

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
