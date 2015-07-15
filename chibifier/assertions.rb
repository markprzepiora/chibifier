module Chibifier
  module Assertions
    # Simple inline assertions.
    #
    # Examples
    #
    #   assert x > 0, "x must be positive, #{x} given"
    #   assert(foo.class == Foo) { "#{foo.inspect} is not an instance of Foo" }
    def assert(condition, message = nil)
      if !condition
        fail(message || yield)
      end
    end

    # Make `assert` method available on the class as well as instances.
    def self.included(other_module)
      other_module.send(:extend, self)
    end
  end
end
