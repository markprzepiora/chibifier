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
          # Secret routes - must add the correct secret as a query param, or
          # these will not match.
          on authorized, "admin" do
            on "codes" do
              # GET /admin/codes
              on get, root do
                res.write shortenr.all_codes_to_urls.to_json
              end

              # GET /admin/codes/:code
              on get, ":code" do |code|
                res.write shortenr.stats_for_code(code).to_json
              end

              # POST /admin/codes
              on post, root, param("url") do |url|
                code = shortenr.add_url(url)
                res.write shortenr.stats_for_code(code).to_json
              end
            end
          end

          # GET /<prefix>/:code
          on get, existing_code_url(shortenr) do |code, url|
            shortenr.increment_clicks(code)
            res.redirect(url)
          end

          # If nothing else matches, 404.
          on true do
            halt_404
          end
        end
      end
    end

    private

    def halt_404
      res.status = 404
      res.write({ error: "Not found" }.to_json)
      halt(res.finish)
    end

    def existing_code_url(shortenr)
      matcher = %r{\A/#{@url_prefix}(?<code>[0-9a-z]+)\z}

      lambda {
        match = env['PATH_INFO'].match(matcher) or return false
        url = shortenr.url_for_code(match[:code]) or return false
        captures.push(match[:code], url)
        true
      }
    end

    def authorized
      lambda { req['secret'] == @secret }
    end
  end
end
