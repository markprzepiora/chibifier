Shortenr: a little URL shortener
================================

This is a work-in-progress. It works! It's fast! But some assembly is required.

Configuration
-------------

Shortenr is configured using environment variables.

- `REDIS_URL` - The Redis database to use. Example:
  `redis://:somepassword@127.0.0.1:6380/2`
- `SHORTENR_SECRET` - The secret string you must pass as a query param to some
  routes (namely adding a new URL and fetching stats). 
- `SHORTENR_NAMESPACE` - If this value is `foo`, then Shortenr will create keys
  in the Redis database with names prefixed by `shortenr-foo:`.

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
