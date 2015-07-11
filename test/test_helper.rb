ENV["SHORTENR_ENV"] ||= 'test'
ENV["RACK_ENV"] ||= 'test'
ENV["SHORTENR_SECRET"] ||= 'test_secret'

require 'bundler/setup'
require 'minitest'
require 'minitest/autorun'
require 'rack/test'
require 'pry'
require_relative '../app'

class ShortenrIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @app ||= begin
      Shortenr::API.new(
        redis_pool: ConnectionPool.new(size: 5, timeout: 5) { Redis.new },
        secret:     'secret',
        namespace:  'test'
      )
    end
  end

  def setup
    app.with_shortenr do |shortenr|
      shortenr.clear_all!('test')
    end
  end

  private \
  def json
    JSON.parse(last_response.body, symbolize_names: true)
  end

  private \
  def authorized_post(url, params = {}, *args, &block)
    post(url, params.merge(secret: 'secret'), *args, &block)
  end

  private \
  def authorized_get(url, params = {}, *args, &block)
    get(url, params.merge(secret: 'secret'), *args, &block)
  end
end
