module ConfigMapper

  module Factory

    def self.resolve(arg)
      return arg if arg.respond_to?(:new)
      return ProcFactory.new(arg) if arg.respond_to?(:call)
      raise ArgumentError, "invalid factory"
    end

  end

  class ProcFactory

    def initialize(f)
      @f = f
    end

    def new
      @f.call
    end

  end

end
