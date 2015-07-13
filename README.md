Chibifier: a little URL shortener
=================================

This is a work-in-progress. It works! It's fast! But some assembly is required.

Dependencies
------------

- Ruby 2.2 (Probably works completely fine in 2.1, but untested.)
- Redis (Tested on 3.0.2, but should work on earlier versions.)

Configuration
-------------

Chibifier is configured using environment variables.

- `REDIS_URL` - The Redis database to use. Example:
  `redis://:somepassword@127.0.0.1:6380/2`
- `CHIBIFIER_SECRET` - The secret string you must pass as a query param to some
  routes (namely adding a new URL and fetching stats). 
- `CHIBIFIER_NAMESPACE` - If this value is `foo`, then Chibifier will create keys
  in the Redis database with names prefixed by `chibifier-foo:`.
- `CHIBIFIER_URL_PREFIX` - If set to `x`, then the server will serve code `123`
  at `/x/123` instead of at `/123`. This can be useful if you want your URLs to
  have clever names.

Usage
-----

You can start the server in development mode using the provided `bin/server`
script, which will run on port 9293.

Adding a URL:

    curl -X POST -d url='https://ruby-lang.org' -H 'X-Chibifier-Secret: changeme' http://127.0.0.1:9293/admin/codes

    # Outputs:
    #
    #   {"code":"fOo","url":"https://ruby-lang.org","clicks":0}

The secret can also be provided in the data.

    curl -X POST -d url='http://redis.io/' -d secret=changeme http://127.0.0.1:9293/admin/codes

    # Outputs:
    #
    #   {"code":"B4r","url":"http://redis.io/","clicks":0}

Visiting a URL:

    curl -i http://127.0.0.1:9293/fOo

    # Outputs:
    #
    #   HTTP/1.1 302 Found
    #   Content-Type: application/json
    #   Location: https://ruby-lang.org
    #   Transfer-Encoding: chunked

Seeing all URLs in the system:

    curl -H 'X-Chibifier-Secret: changeme' http://127.0.0.1:9293/admin/codes

    # Outputs:
    #
    #   {"fOo":"https://ruby-lang.org","B4r":"http://redis.io/"}

Checking a URL's stats:

    curl -H 'X-Chibifier-Secret: changeme' http://127.0.0.1:9293/admin/codes/fOo

    # Outputs:
    #
    #   {"code":"fOo","url":"https://ruby-lang.org","clicks":1}

Chibifier generates codes as random, alphanumeric strings three characters in
length or longer. Please be aware that there is no blacklist for codes, so you
can end up with obscene codes.

Is it good?
-----------

On my development machine, it can serve more than 2200 requests per second:

    Concurrency Level:      32
    Time taken for tests:   0.443 seconds
    Complete requests:      1000
    Failed requests:        0
    Write errors:           0
    Non-2xx responses:      1000
    Total transferred:      86000 bytes
    HTML transferred:       0 bytes
    Requests per second:    2255.97 [#/sec] (mean)
    Time per request:       14.185 [ms] (mean)
    Time per request:       0.443 [ms] (mean, across all concurrent requests)
