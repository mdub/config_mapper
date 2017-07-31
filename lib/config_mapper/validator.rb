module ConfigMapper

  module Validator

    def self.resolve(arg)
      return arg if arg.respond_to?(:call)
      if arg.respond_to?(:name)
        # looks like a primitive class -- find the corresponding coercion method
        return Kernel.method(arg.name)
      end
      arg
    end

  end

end
