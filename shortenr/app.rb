require 'bundler/setup'

module Shortenr
  class App
    def initialize(redis:, namespace:)
      @redis = redis
      @namespace = namespace
    end

    # Public API

    def url_for_code(code)
      redis.hget(key_for_code(code), :url)
    end

    def add_url(url)
      code_for_url(url) || add_new_url(url)
    end

    def stats_for_code(code)
      key = key_for_code(code)
      { code: code, url: redis.hget(key, :url), clicks: redis.hget(key, :clicks).to_i }
    end

    def increment_clicks(code)
      key = key_for_code(code)
      redis.hincrby key, :clicks, 1
    end

    # Debug functions

    # DANGER - be careful with this.
    def clear_all!(namespace = nil)
      unless namespace && (namespace == @namespace)
        fail "you must call clear_all! with the current namespace - e.g. clear_all!('development')"
      end

      redis.keys(key("*")).each{ |key| redis.del(key) }
    end

    # Debug function - get a hash of all URLs mapped to their codes.
    def all_urls_to_codes
      redis.hgetall(key("reverse_lookup"))
    end

    # Debug function - the inverse of the above.
    def all_codes_to_urls
      all_urls_to_codes.invert
    end

    # Debug function - delete a URL by its code
    def delete_code(code)
      url = url_for_code(code) or return
      redis.del key_for_code(code)
      redis.hdel key("reverse_lookup"), url
    end

    # Debug function - delete a URL
    def delete_url(url)
      code = code_for_url(url) or return
      redis.del key_for_code(code)
      redis.hdel key("reverse_lookup"), url
    end

    private

    def redis
      @redis
    end

    def key(key)
      "#{prefix}:#{key}"
    end

    def key_for_code(code)
      key("codes:#{code}")
    end

    def add_new_url(url)
      begin
        num = redis.incr(key("last_code_number"))
        code = num.to_s(36)
      end while url_for_code(code)
      add_new_code(code, url)
    end

    def add_new_code(code, url)
      code_key = key_for_code(code)

      assert !redis.exists(code_key), "Tried to add #{code}, #{url} but code #{code} already exists."

      redis.hset(code_key, :url, url)
      redis.hset(code_key, :clicks, 0)
      redis.hset(key("reverse_lookup"), url, code)
      code
    end

    def code_for_url(url)
      redis.hget(key("reverse_lookup"), url)
    end

    def assert(condition, message = nil)
      if !condition
        fail message || yield
      end
    end

    def prefix
      'shortenr-' + @namespace
    end
  end
end
