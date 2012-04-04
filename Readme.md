# Ruby Easter Contest

This is my solution for the [Ruby Easter Contest](http://contest.dimelo.com/)
by Dimelo.

## Requirements

* Redis server, version >= 2.0

* Ruby1.9.3 (though it should work with Ruby1.8.7+)

## Technological choices

* Based on the requirements, requests need only to be stored for up to 5
  minutes. Redis is a good candidate because we can assign expiration dates to
  entries. However, we can't make range queries on single items (except with
  the KEYS command, which is not recommended for production use). Therefore,
  we'll store the values in a Redis set (which allows range queries), and we
  will expire the old values with the `script/clean` script (see [this thread]
  [thread] for more explanation).

[thread]:  http://groups.google.com/group/redis-db/browse_thread/thread/ad75cc08b364352b

* Redis is also a good choice because it allows for sharing data between all
  processes.

* To ensure that we have a standard base time for all requests, it would
  have been useful to make use of the TIME command of Redis, so that all
  requests are stored based on the Redis server time and not the local time of
  the process(es) (we're not interested in true accuracy but we want our
  requests to be ordered in chronological order). However, this command is
  available starting from version 2.6 only, which is not packaged in Homebrew
  (and other package managers I guess) yet. Therefore we won't do anything
  about ensuring true synchronization. Note that usually the servers should be
  synchronized using an NTP client, which mitigate the issue.

* To avoid having requests being overwritten in the Redis set (for instance,
  when request throughput coming from a single client is very high -- i.e.
  benchmarking tool), special care is given to ensure that each request entry
  in Redis is unique enough to be kept in the log.

* To avoid counting all visitors coming from behind a NAT'ed address to be
  counted as only one unique visitor, we take into account the User-Agent AND
  IP (it has been shown that the user-agent is a surprisingly good
  identifier). Therefore:

        unique_visitors = COUNT(DISTINCT(IP, USER-AGENT))

* Finally, the code is thread safe, since it does not reuse internal data
  structure to store things between requests, and the redis-rb library itself
  is thread-safe starting from version >= 2.2.0.

## Usage

* Install Redis. If you're on MacOS and running Homebrew you can do:

        $ brew install redis
        $ redis-server

* Install dependencies:

        $ bundle install

* Launch the example app:

        $ bundle exec rackup config.ru

* Make some requests:

        $ curl http://localhost:9292/hello

  Note that if you want to use the silo feature, you'll have to add an
  additional middleware before `Rack::LiveTraffic`, which will set the
  `rack.livetraffic_id` environment variable (you can also change the name of
  that variable in the options of `Rack::LiveTraffic`, so that you can use
  Apache or whatever to set an additional HTTP header, instead of a Rack
  environment variable that only a middleware can set).

* To fetch the stats, run:

        $ bundle exec script/rack-top

* From time to time, you may want to clean up old values from Redis:

        $ bundle exec script/clean

## Author & Copyright

[Cyril Rohr](http://crohr.me) - Public Domain.
