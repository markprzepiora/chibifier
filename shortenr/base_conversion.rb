require_relative 'assertions'

# Ruby's Fixnum#to_s(base) only works for base <= 36 ("0" through "z"). This
# supports bases up to 62 ("0", ..., "9", "a", ..., "z", "A", ..., "Z").
module Shortenr
  module BaseConversion
    extend Assertions

    def self.number_in_base(number, base)
      assert(number >= 0) { "number must be non-negative, #{number} given" }
      assert((2..62).include?(base)) { "base must be between 2 and 62, #{base} given" }
      base_components(number, base).map{ |n| to_char(n) }.join
    end

    private_class_method \
    def self.base_components(x, base)
      components = []
      q, r = x, nil
      begin
        q, r = q.divmod(base)
        components << r
      end while q > 0
      components.reverse
    end

    private_class_method \
    def self.to_char(x)
      case x
      when 0..9 then x.to_s
      when 10...36 then (x+97-10).chr
      when 36...62 then (x+65-36).chr
      else
        fail("input must be between 0 and 61")
      end
    end
  end
end
