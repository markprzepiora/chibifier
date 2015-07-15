require_relative 'assertions'

# Ruby's Fixnum#to_s(base) only works for base <= 36 ("0" through "z"). This
# supports bases up to 62 ("0", ..., "9", "a", ..., "z", "A", ..., "Z").
module Chibifier
  module BaseConversion
    BASE_62_DIGITS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a

    include Assertions

    def self.number_in_base(number, base)
      assert(number >= 0) { "number must be non-negative, #{number} given" }
      assert((2..62).include?(base)) { "base must be between 2 and 62, #{base} given" }
      base_components(number, base).map{ |n| to_char(n) }.join
    end

    private_class_method \
    def self.base_components(q, base)
      components = []
      begin
        q, r = q.divmod(base)
        components << r
      end while q > 0
      components.reverse
    end

    private_class_method \
    def self.to_char(x)
      assert((0..61).include?(x)) { "input must be between 0 and 61, #{x} given" }
      BASE_62_DIGITS[x]
    end
  end
end
