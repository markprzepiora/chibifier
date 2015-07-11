ENV["RACK_ENV"] ||= 'development'

require 'bundler/setup'
require 'connection_pool'
require 'redis'
require "./app"

redis_pool = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }
run Shortenr::API.new(
  redis_pool: redis_pool,
  secret:     ENV["SHORTENR_SECRET"] || 'foobarbaz',
  namespace:  ENV["SHORTENR_NAMESPACE"] || ENV["RACK_ENV"]
)
