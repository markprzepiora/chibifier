require_relative 'test_helper'

Class.new(ShortenrUnitTest) do
  def test_adding_and_retrieving_urls
    code_1 = app.add_url("http://www.google.ca")
    code_2 = app.add_url("http://www.google.ca")
    code_3 = app.add_url("http://www.google.com")

    # All three URLs should be unique
    assert_equal 3, [code_1, code_2, code_3].uniq.count

    assert_equal "http://www.google.ca", app.url_for_code(code_1)
    assert_equal "http://www.google.ca", app.url_for_code(code_2)
    assert_equal "http://www.google.com", app.url_for_code(code_3)
  end

  def test_incrementing_clicks_and_generating_stats
    code = app.add_url("http://www.google.ca")
    app.increment_clicks(code)
    app.increment_clicks(code)

    stats = app.stats_for_code(code)
    assert_equal 2, stats[:clicks]
  end

  def test_stats
    code = app.add_url("http://www.google.ca")
    stats = app.stats_for_code(code)

    assert_equal 0, stats[:clicks]
    assert_equal "http://www.google.ca", stats[:url]
    assert_equal code, stats[:code]
  end

  def test_delete_code
    code_1 = app.add_url("http://www.google.ca")
    code_2 = app.add_url("http://www.google.ca")

    app.delete_code(code_1)

    assert_equal nil, app.url_for_code(code_1)
    assert_equal "http://www.google.ca", app.url_for_code(code_2)
  end
end
