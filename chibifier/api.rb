require 'bundler/setup'
require 'cuba'
require 'json'

require_relative 'app'

module Chibifier
  class API < Cuba
    def with_chibifier
      @redis_pool.with do |redis|
        chibifier = Chibifier::App.new(redis: redis, namespace: @namespace)
        yield(chibifier)
      end
    end

    def initialize(redis_pool:, secret:, namespace:, url_prefix:)
      url_prefix = (url_prefix && url_prefix != "") ? "#{url_prefix}/" : ""

      @redis_pool = redis_pool
      @secret     = secret
      @namespace  = namespace
      @code_url_matcher = %r{
        \A
        /                      # start with a slash:             /
        #{url_prefix}          # followed by the prefix if any:  ra/
        (?<code>[0-9a-zA-Z]+)  # then the code itself:           f0o
        \z
      }x

      super() do
        res["Content-Type"] = "application/json"

        with_chibifier do |chibifier|
          # Secret routes - must add the correct secret as a query param, or
          # these will not match.
          on authorized, "admin" do
            on "codes" do
              # GET /admin/codes
              on get, root do
                res.write chibifier.all_codes_to_urls.to_json
              end

              # GET /admin/codes/:code
              on get, ":code" do |code|
                res.write chibifier.stats_for_code(code).to_json
              end

              # POST /admin/codes
              on post, root, param("url") do |url|
                code = chibifier.add_url(url)
                res.write chibifier.stats_for_code(code).to_json
              end
            end
          end

          # GET /<prefix>/:code
          on get, existing_code_url(chibifier) do |code, url|
            chibifier.increment_clicks(code)
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

    def existing_code_url(chibifier)
      lambda {
        match = env['PATH_INFO'].match(@code_url_matcher) or return false
        url = chibifier.url_for_code(match[:code]) or return false
        captures.push(match[:code], url)
        true
      }
    end

    def authorized
      lambda do
        (req['secret'] == @secret) ||
        (env['HTTP_X_CHIBIFIER_SECRET'] == @secret)
      end
    end
  end
end
