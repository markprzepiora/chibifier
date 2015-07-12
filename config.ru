ENV["RACK_ENV"] ||= 'development'

require 'bundler/setup'
require 'connection_pool'
require 'redis'
require './shortenr/api'

redis_pool = ConnectionPool.new(size: 32, timeout: 5) { Redis.new }
run Shortenr::API.new(
  redis_pool: redis_pool,
  secret:     ENV["SHORTENR_SECRET"] || 'changeme',
  namespace:  ENV["SHORTENR_NAMESPACE"] || ENV["RACK_ENV"],
  url_prefix: ENV["SHORTENR_URL_PREFIX"]
)
