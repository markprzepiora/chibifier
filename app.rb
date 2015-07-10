require 'bundler/setup'
require 'cuba'
require 'json'

require_relative 'minifier'

Cuba.define do
  # Secret routes
  on param("secret") do |secret|
    if secret != SECRET
      res.status = 404
      res.write "Not found"
      halt(res.finish)
    end

    on get, 'ra/:code/stats' do |code|
      res.write stats_for_code(code).to_json
    end

    on post, root, param("url") do |url|
      code = add_url(url)
      res.write stats_for_code(code).to_json
    end
  end

  on get, 'ra/:code' do |code|
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
