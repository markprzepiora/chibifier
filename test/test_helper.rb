ENV["CHIBIFIER_ENV"] ||= 'test'
ENV["RACK_ENV"] ||= 'test'
ENV["CHIBIFIER_SECRET"] ||= 'test_secret'

require 'bundler/setup'
require 'minitest'
require 'minitest/autorun'
require 'rack/test'
require 'pry'
require 'connection_pool'
require 'redis'

require_relative '../chibifier/api'

class ChibifierIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    app.with_chibifier do |chibifier|
      chibifier.clear_all!('test')
    end
  end

  private

  def app
    @app ||= begin
      Chibifier::API.new(
        redis_pool: ConnectionPool.new(size: 5, timeout: 5) { Redis.new },
        secret:     'secret',
        namespace:  'test',
        url_prefix: 'ra'
      )
    end
  end

  def json
    JSON.parse(last_response.body, symbolize_names: true)
  end

  def authorized_post(url, params = {}, *args, &block)
    post(url, params.merge(secret: 'secret'), *args, &block)
  end

  def authorized_get(url, params = {}, *args, &block)
    get(url, params.merge(secret: 'secret'), *args, &block)
  end
end

class ChibifierUnitTest < Minitest::Test
  def setup
    app.clear_all!('test')
  end

  private

  def app
    @app ||= Chibifier::App.new(redis: redis, namespace: 'test')
  end

  def redis
    @redis ||= Redis.new
  end
end
