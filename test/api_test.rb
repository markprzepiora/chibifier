require_relative 'test_helper'

Class.new(ChibifierIntegrationTest) do
  def test_adding_url
    code = add_url("http://www.google.ca")

    assert_equal 200, last_response.status
    refute_empty json[:code]
    assert_equal "http://www.google.ca", json[:url]
    assert_equal 0, json[:clicks]
  end

  def test_adding_same_url_twice
    code         = add_url("http://www.google.ca")
    another_code = add_url("http://www.google.ca")

    refute_equal code, another_code

    assert_equal 200, last_response.status
    assert_equal "http://www.google.ca", json[:url]
    assert_equal 0, json[:clicks]
  end

  def test_adding_several_urls
    codes = [
      add_url("http://www.google.ca"),
      add_url("http://www.google.com"),
      add_url("http://www.google.co.uk")
    ]

    assert_equal 3, codes.uniq.count

    assert_equal 200, last_response.status
    assert_equal "http://www.google.co.uk", json[:url]
    assert_equal 0, json[:clicks]
  end

  def test_visiting_url
    code = add_url("http://www.google.ca")
    get "/ra/#{code}"

    assert_equal "http://www.google.ca", last_response.header["Location"]
  end

  def test_visiting_with_invalid_code
    code = add_url("http://www.google.ca")
    get "/ra/123123123"

    assert_equal 404, last_response.status
  end

  def test_visit_counter
    code = add_url("http://www.google.ca")
    get "/ra/#{code}"
    get "/ra/#{code}"

    authorized_get "/admin/codes/#{code}"

    assert_equal 2, json[:clicks]
  end

  def test_stats_when_unauthorized
    code = add_url("http://www.google.ca")
    get "/admin/codes/#{code}"

    assert_equal 404, last_response.status
    assert_equal({ error: "Not found" }, json)
  end

  def test_adding_url_when_unauthorized
    post "/admin/codes", url: "http://www.google.ca"

    assert_equal 404, last_response.status
    assert_equal({ error: "Not found" }, json)
  end

  private

  def add_url(url)
    authorized_post "/admin/codes", url: url
    json[:code]
  end
end

Class.new(ChibifierIntegrationTest) do
  def test_fetching_an_empty_prefix
    code = add_url("http://bing.com")
    get "/#{code}"

    assert_equal "http://bing.com", last_response.header["Location"]
  end

  def test_admin_pages_with_empty_prefix
    code = add_url("http://bing.com")
    authorized_get "/admin/codes/#{code}"

    assert_equal "http://bing.com", json[:url]
  end

  private

  def app
    @app ||= begin
      Chibifier::API.new(
        redis_pool: ConnectionPool.new(size: 5, timeout: 5) { Redis.new },
        secret:     'secret',
        namespace:  'test',
        url_prefix: ''
      )
    end
  end

  def add_url(url)
    authorized_post "/admin/codes", url: url
    json[:code]
  end
end
