require 'bundler/setup'
require 'cuba'
require 'json'
require 'connection_pool'

require_relative 'minifier'

$redis_pool = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }

Cuba.define do
  $redis_pool.with do |redis|
    shortenr = Shortenr.new(redis)

    # Secret routes
    on param("secret") do |secret|
      if secret != SECRET
        res.status = 404
        res.write "Not found"
        halt(res.finish)
      end

      on get, 'ra/:code/stats' do |code|
        res.write shortenr.stats_for_code(code).to_json
      end

      on post, root, param("url") do |url|
        code = shortenr.add_url(url)
        res.write shortenr.stats_for_code(code).to_json
      end
    end

    on get, 'ra/:code' do |code|
      url = shortenr.url_for_code(code)

      if url
        shortenr.increment_clicks(code)
        res.redirect url
      else
        res.status = 404
        res.write "Not found"
      end
    end
  end
end
