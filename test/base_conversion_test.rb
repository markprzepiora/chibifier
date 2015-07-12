require_relative 'test_helper'
require_relative '../shortenr/base_conversion'

Class.new(Minitest::Test) do
  def test_happy_paths
    assert_equal "0", number_in_base(0, 62)
    assert_equal "1", number_in_base(1, 62)
    assert_equal "9", number_in_base(9, 62)
    assert_equal "a", number_in_base(10, 62)
    assert_equal "A", number_in_base(36, 62)
    assert_equal "Z", number_in_base(61, 62)
    assert_equal "10", number_in_base(62, 62)
    assert_equal "1Z", number_in_base(62 + 61, 62)
  end

  private

  def number_in_base(*args, &block)
    Shortenr::BaseConversion.number_in_base(*args, &block)
  end
end
