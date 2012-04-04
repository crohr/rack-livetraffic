$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'rack/live_traffic'

# Example middleware to set rack.livetraffic_id variable.
#
# class Silo
#   def initialize(app, name); @app = app; @name = name; end
#   def call(env); env['rack.livetraffic_id'] = @name; @app.call(env); end
# end
# 
# use Silo, "some-id"

use Rack::LiveTraffic, {} #puts here your storage/discovery options if needed

app = proc do |env|
  [ 200, {'Content-Type' => 'text/plain'}, ['OK'] ]
end

run app