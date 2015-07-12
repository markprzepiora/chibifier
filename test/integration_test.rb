require_relative 'test_helper'

Class.new(ShortenrIntegrationTest) do
  def test_adding_url
    add_url "http://www.google.ca"

    assert_equal 200, last_response.status
    assert_equal "1", json[:code]
    assert_equal "http://www.google.ca", json[:url]
    assert_equal 0, json[:clicks]
  end

  def test_adding_same_url_twice
    add_url "http://www.google.ca"
    add_url "http://www.google.ca"

    assert_equal 200, last_response.status
    assert_equal "1", json[:code]
    assert_equal "http://www.google.ca", json[:url]
    assert_equal 0, json[:clicks]
  end

  def test_adding_several_urls
    add_url "http://www.google.ca"
    add_url "http://www.google.com"
    add_url "http://www.google.co.uk"

    assert_equal 200, last_response.status
    assert_equal "3", json[:code]
    assert_equal "http://www.google.co.uk", json[:url]
    assert_equal 0, json[:clicks]
  end

  def test_visiting_url
    add_url "http://www.google.ca"
    get "/ra/1"

    assert_equal "http://www.google.ca", last_response.header["Location"]
  end

  def test_visiting_with_invalid_code
    add_url "http://www.google.ca"
    get "/ra/123"

    assert_equal 404, last_response.status
  end

  def test_visit_counter
    add_url "http://www.google.ca"
    get "/ra/1"
    get "/ra/1"

    authorized_get "/admin/codes/1"

    assert_equal 2, json[:clicks]
  end

  def test_stats_when_unauthorized
    add_url "http://www.google.ca"
    get "/admin/codes/1"

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

Class.new(ShortenrIntegrationTest) do
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
      Shortenr::API.new(
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
