require 'securerandom'
require_relative 'base_conversion'

module Shortenr
  module RandomCodeGenerator
    def self.codes(conn)
      return to_enum(__callee__, conn).lazy unless block_given?

      while true
        num = SecureRandom.random_number(1099511627776)
        long_code = BaseConversion.number_in_base(num, 62)

        # long_code = "foobarbaz"
        (3..long_code.length).each do |length|
          # short_code = "foo", "foob", ...
          short_code = long_code.slice(0, length)
          yield short_code
        end
      end
    end
  end
end
