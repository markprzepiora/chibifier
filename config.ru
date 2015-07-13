ENV["RACK_ENV"] ||= 'development'

require 'bundler/setup'
require 'connection_pool'
require 'redis'
require './chibifier/api'

redis_pool = ConnectionPool.new(size: 32, timeout: 5) { Redis.new }
run Chibifier::API.new(
  redis_pool: redis_pool,
  secret:     ENV["CHIBIFIER_SECRET"] || 'changeme',
  namespace:  ENV["CHIBIFIER_NAMESPACE"] || ENV["RACK_ENV"],
  url_prefix: ENV["CHIBIFIER_URL_PREFIX"]
)
