require File.expand_path('../../lib/faye/redis', __FILE__)
require 'websocket/driver'
require File.expand_path('../../vendor/faye/spec/ruby/engine_examples', __FILE__)

class << Faye
  attr_accessor :logger
end
