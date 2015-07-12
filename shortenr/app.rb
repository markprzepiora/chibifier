require 'bundler/setup'
require_relative 'assertions'
require_relative 'base_conversion'

module Shortenr
  class App
    include Assertions

    # Public: Initialize a new Shortenr instance.
    #
    # redis     - A Redis instance.
    # namespace - A string like "development". In this case, Shortenr will
    #             create keys in Redis prefixed with "shortenr-development:".
    def initialize(redis:, namespace:)
      @redis = redis
      @namespace = namespace
    end

    # Public: Look up the full-length URL for a given short code.
    #
    # code - The minified String code to decode.
    #
    # Examples
    #
    #   url_for_code('123')
    #   # => "http://www.google.ca"
    #
    #   url_for_code('124')
    #   # => nil
    #
    # Returns a URL String, or nil if the code does not exist.
    def url_for_code(code)
      redis.hget(key_for_code(code), :url)
    end

    # Public: Add a URL to the database, either generating a new code or
    # looking up its existing one.
    #
    # url - a URL String
    #
    # Examples
    #
    #   add_url("http://www.google.ca")
    #   # => "1"
    #
    #   add_url("http://www.bing.com")
    #   # => "2"
    #
    #   add_url("http://www.google.ca")
    #   # => "1"
    #
    # Returns a short code String, which may have already existed in the
    # database before the call.
    def add_url(url)
      code_for_url(url) || add_new_url(url)
    end

    # Public: Generate some statistics for a given code.
    #
    # code - A minified String code.
    #
    # Examples
    #
    #   stats_for_code("1")
    #   # => { code: "1", url: "http://www.google.ca", clicks: 5 }
    #
    #   stats_for_code("3")
    #   # => { code: "3", url: nil, clicks: 0 }
    #
    # Returns a hash with keys :code, :url, and :clicks. If the input code does
    # not exist in the database, then the :url value will be nil, and :clicks
    # will be 0.
    def stats_for_code(code)
      key = key_for_code(code)
      { code: code, url: redis.hget(key, :url), clicks: redis.hget(key, :clicks).to_i }
    end

    # Public: Increment the number of times a given code has been visited.
    #
    # code - A minified String code.
    #
    # Examples
    #
    #   increment_clicks("1")
    #   # => 5
    #
    #   increment_clicks("1")
    #   # => 6
    #
    # Returns the new number of clicks. Calling this with a nonexistent code
    # produces undefined behaviour.
    def increment_clicks(code)
      key = key_for_code(code)
      redis.hincrby key, :clicks, 1
    end

    # Public: Delete all saved data.
    #
    # namespace - The name of the current namespace. If not entered correctly,
    #             the operation will not continue.
    #
    # Returns an array of the keys that have been deleted.
    def clear_all!(namespace = nil)
      unless namespace && (namespace == @namespace)
        fail "you must call clear_all! with the current namespace - e.g. clear_all!('development')"
      end

      redis.keys(key("*")).each{ |key| redis.del(key) }
    end

    # Public: Generate a hash of all saved URLs -> codes in the database.
    #
    # Examples
    #
    #   all_urls_to_codes
    #   # => { "http://www.google.ca" => "1", "http://www.bing.com" => "2" }
    def all_urls_to_codes
      redis.hgetall(key("reverse_lookup"))
    end

    # Public: Generate a hash of all saved codes -> URLs in the database.
    #
    # Examples
    #
    #   all_codes_to_urls
    #   # => { "1" => "http://www.google.ca", "2" => "http://www.bing.com" }
    def all_codes_to_urls
      all_urls_to_codes.invert
    end

    # Public: Delete a code.
    #
    # code - A minified String code.
    #
    # Examples
    #
    #   add_url("http://www.bing.com")
    #   # => "2"
    #   delete_code("2")
    #   # => 1
    #   delete_code("2")
    #   # => nil
    #
    # Returns 1 if a code was deleted, nil else.
    def delete_code(code)
      url = url_for_code(code) or return
      redis.del key_for_code(code)
      redis.hdel key("reverse_lookup"), url
    end

    # Public: Delete a URL.
    #
    # url - a URL String.
    #
    # Examples
    #
    #   add_url("http://www.bing.com")
    #   delete_url("http://www.bing.com")
    #   # => 1
    #   delete_url("http://www.bing.com")
    #   # => nil
    #
    # Returns 1 if the URL was deleted, nil else.
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
        code = BaseConversion.number_in_base(num, 62)
      end until verify_new_code(code)
      add_new_code(code, url)
    end

    def verify_new_code(code)
      !url_for_code(code)
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

    def prefix
      'shortenr-' + @namespace
    end
  end
end
