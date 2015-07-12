require 'bundler/setup'
require 'cuba'
require 'json'

require_relative 'app'

module Shortenr
  class API < Cuba
    def with_shortenr
      @redis_pool.with do |redis|
        shortenr = Shortenr::App.new(redis: redis, namespace: @namespace)
        yield(shortenr)
      end
    end

    def initialize(redis_pool:, secret:, namespace:, url_prefix:)
      @redis_pool = redis_pool
      @secret     = secret
      @namespace  = namespace
      @url_prefix = (url_prefix && url_prefix != "") ? "#{url_prefix}/" : ""

      super() do
        res["Content-Type"] = "application/json"

        with_shortenr do |shortenr|
          # Secret routes
          on authorized, "admin" do
            on get, "codes/:code/stats" do |code|
              res.write shortenr.stats_for_code(code).to_json
            end

            on post, "codes", param("url") do |url|
              code = shortenr.add_url(url)
              res.write shortenr.stats_for_code(code).to_json
            end

            on get, "debug" do
              res.write(
                Hash[*instance_variables.map{ |n| [n, instance_variable_get(n)] }.flatten(1)].
                to_json
              )
            end
          end

          on get, existing_code_url(shortenr) do |code, url|
            shortenr.increment_clicks(code)
            res.redirect(url)
          end

          on true do
            halt_404
          end
        end
      end
    end

    private \
    def halt_404
      res.status = 404
      res.write({ error: "Not found" }.to_json)
      halt(res.finish)
    end

    private \
    def existing_code_url(shortenr)
      matcher = %r{\A/#{@url_prefix}(?<code>[0-9a-z]+)\z}

      lambda {
        match = env['PATH_INFO'].match(matcher) or return false
        url = shortenr.url_for_code(match[:code]) or return false
        captures.push(match[:code], url)
        true
      }
    end

    private \
    def authorized
      lambda { req['secret'] == @secret }
    end
  end
end
