module Chibifier
  module Assertions
    def self.assert(condition, message = nil)
      if !condition
        fail message || yield
      end
    end

    def assert(*args)
      Assertions.assert(*args)
    end
  end
end
