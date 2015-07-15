require 'bundler/setup'
require 'forwardable'
require_relative 'assertions'
require_relative 'random_code_generator'

module Chibifier
  class Connection < Struct.new(:redis, :namespace)
    # Examples
    #
    #   key
    #   # => "chibifier-test"
    #
    #   key(:codes)
    #   # => "chibifier-test:codes"
    #
    #   key(:codes, "abc")
    #   # => "chibifier-test:codes:abc"
    def key(*keys)
      ["chibifier-#{namespace}", *keys].join(":")
    end
  end

  class App
    include Assertions
    extend Forwardable

    def_delegators :@connection, :redis, :namespace, :key

    # Public: Initialize a new Chibifier instance.
    #
    # redis     - A Redis instance.
    # namespace - A string like "development". In this case, Chibifier will
    #             create keys in Redis prefixed with "chibifier-development:".
    def initialize(redis:, namespace:)
      @connection = Connection.new(redis, namespace)
    end

    # Public: Create a short code for a given URL.
    #
    # url - The URL we are minifying.
    #
    # Returns the new code on success, nil on (extremely unlikely) failure.
    def add_url(url)
      RandomCodeGenerator.codes(@connection).take(100).find do |code|
        add_new_code(code, url)
      end
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
      redis.hincrby(key, :clicks, 1)
    end

    # Public: Delete all saved data.
    #
    # namespace - The name of the current namespace. If not entered correctly,
    #             the operation will not continue.
    #
    # Returns an array of the keys that have been deleted.
    def clear_all!(given_namespace = nil)
      unless given_namespace && (given_namespace == namespace)
        fail "you must call clear_all! with the current namespace - e.g. clear_all!('development')"
      end

      redis.keys(key("*")).each{ |key| redis.del(key) }
    end

    # Public: Generate a hash of all saved codes -> URLs in the database.
    # Warning: This is not a particularly efficient operation.
    #
    # Examples
    #
    #   all_codes_to_urls
    #   # => { "1" => "http://www.google.ca", "2" => "http://www.bing.com" }
    def all_codes_to_urls
      codes_and_urls = redis.smembers(key(:codes)).map do |code|
        [code, url_for_code(code)]
      end

      Hash[*codes_and_urls.flatten(1)]
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
    #   # => true
    #   delete_code("2")
    #   # => nil
    #
    # Returns true if a code was deleted, nil else.
    def delete_code(code)
      result = redis.multi do
        redis.del(key_for_code(code))
        redis.srem(key(:codes), code)
      end

      result == [1, true]
    end

    private

    def key_for_code(code)
      key(:codes, code)
    end

    # Private: Try to add a new URL at a given code.
    #
    # code - The short code to use.
    # url  - The URL to redirect to.
    #
    # Returns true on success, false if the code is unavailable.
    def add_new_code(code, url)
      code_key = key_for_code(code)

      result = redis.multi do
        redis.sadd(key("codes"), code)
        redis.hsetnx(code_key, :url, url)
        redis.hsetnx(code_key, :clicks, 0)
      end

      result == [true, true, true]
    end
  end
end
