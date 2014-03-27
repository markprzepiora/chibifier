require 'rubygems'
require 'bundler/setup'

require 'redis'
require 'cuba'
require 'securerandom'
require 'json'

$redis = Redis.new

def key_for_code(code)
  "minifier:#{code}"
end

def url_for_code(code)
  $redis.hget key_for_code(code), :url
end

def new_code
  begin
    code = SecureRandom.hex(3)
  end while url_for_code(code)
  code
end

def add_new_code(code, url)
  key = key_for_code(code)
  $redis.hset key, :url, url
  $redis.hset key, :clicks, 0
  code
end

def add_new_url(url)
  add_new_code(new_code, url)
end

def stats_for_code(code)
  key = key_for_code(code)
  { url: $redis.hget(key, :url), clicks: $redis.hget(key, :clicks) }
end

def increment_clicks(code)
  key = key_for_code(code)
  $redis.hincrby key, :clicks, 1
end


Cuba.define do
  on get do
    on get, ':code/stats', param("secret") do |code, secret|
      if secret == ENV["SHORTENR_SECRET"]
        res.write stats_for_code(code).to_json
      else
        res.status = 404
        res.write "Not found"
      end
    end

    on get, /([a-f0-9]+)/ do |code|
      url = url_for_code(code)

      if url
        increment_clicks(code)
        res.redirect url
      else
        res.status = 404
        res.write "Not found"
      end
    end
  end
end
