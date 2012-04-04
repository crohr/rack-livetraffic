require 'redis'
require 'uri'
require 'digest/sha1'
require 'rack/request'

module Rack
  class LiveTraffic
    # Initialize the Rack middleware with an +app+.
    # The +opts+ Hash can contain the following options:
    #
    # :traffic_key:: the environment variable that contains the silo ID (if any). Defaults to 'rack.livetraffic_id'.
    # :set:: the name of the Redis set which will store the requests. Defaults to 'requests'.
    # :redis:: the Redis URI. Defaults to 'redis://127.0.0.1:6379'
    def initialize(app, opts = {})
      @app = app
      @traffic_key = opts[:traffic_key] || 'rack.livetraffic_id'
      @set = opts[:set] || "requests"

      store_uri = URI.parse(opts[:redis] || "redis://127.0.0.1:6379")
      @redis = Redis.new(:host => store_uri.host, :port => store_uri.port)
    end

    def call(env)
      now = Time.now
      request = Rack::Request.new(env)

      result, duration = time(now) { @app.call(env) }

      store(
        now,
        request.env[@traffic_key],
        request.ip,
        request.url,
        # Compute user-agent fingerprint
        Digest::SHA1.hexdigest(request.user_agent),
        duration,
        # Used to ensure that no other request will have the exact same values
        rand(10000)
      )

      result
    end

    # Store the request +values+ at +key+ in the Redis set. Will silently fail
    # if the Redis connection is not available. Values are concatenated with a
    # semi-colon between each value.
    def store(key, *values)
      @redis.zadd @set, key.to_f, values.join(";")
    rescue Errno::ECONNREFUSED => e
      env['rack.errors'].write "#{e.class.name} - #{e.message}\n"
    end

    # Computes the time (in milliseconds) it takes to execute the given block.
    # Returns an Array of the form <tt>[result, time]</tt>.
    def time(base = nil)
      base ||= Time.now
      [yield, (Time.now-base)*1000]
    end
  end
end