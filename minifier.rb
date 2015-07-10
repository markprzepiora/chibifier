require 'bundler/setup'
require 'redis'

NAMESPACE = 'shortenr-' + (ENV['SHORTENR_NAMESPACE'] || 'development')
SECRET = ENV["SHORTENR_SECRET"] || 'foobarbaz'
$redis = Redis.new

def assert(condition, message = nil)
  if !condition
    fail message || yield
  end
end

# DANGER - be careful with this.
def clear_all!(namespace = nil, confirmation = nil)
  unless namespace && confirmation && (confirmation == namespace)
    fail "you must call clear_all! with the namespace to delete twice - e.g. clear_all!('development', 'development')"
  end

  $redis.keys("shortenr-#{namespace}:*").each{ |key| $redis.del(key) }
end

def key_for_code(code)
  "#{NAMESPACE}:codes:#{code}"
end

def url_for_code(code)
  $redis.hget(key_for_code(code), :url)
end

# Debug function - get a hash of all URLs mapped to their codes.
def all_urls_to_codes
  $redis.hgetall("#{NAMESPACE}:reverse_lookup")
end

# Debug function - the inverse of the above.
def all_codes_to_urls
  all_urls_to_codes.invert
end

# Debug function - delete a URL by its code
def delete_code(code)
  url = url_for_code(code) or return
  $redis.del key_for_code(code)
  $redis.hdel "#{NAMESPACE}:reverse_lookup", url
end

def delete_url(url)
  code = code_for_url(url) or return
  $redis.del key_for_code(code)
  $redis.hdel "#{NAMESPACE}:reverse_lookup", url
end

def add_url(url)
  code_for_url(url) || add_new_url(url)
end

  def code_for_url(url)
    $redis.hget("#{NAMESPACE}:reverse_lookup", url)
  end

def add_new_url(url)
  begin
    num = $redis.incr("#{NAMESPACE}:last_code_number")
    code = num.to_s(36)
  end while url_for_code(code)
  add_new_code(code, url)
end

  def add_new_code(code, url)
    key = key_for_code(code)

    assert !$redis.exists(key), "Tried to add #{code}, #{url} but code #{code} already exists."

    $redis.hset(key, :url, url)
    $redis.hset(key, :clicks, 0)
    $redis.hset("#{NAMESPACE}:reverse_lookup", url, code)
    code
  end

def stats_for_code(code)
  key = key_for_code(code)
  { code: code, url: $redis.hget(key, :url), clicks: $redis.hget(key, :clicks) }
end

def increment_clicks(code)
  key = key_for_code(code)
  $redis.hincrby key, :clicks, 1
end
