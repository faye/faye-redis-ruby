require "spec_helper"

describe Faye::Redis do
  let(:engine_opts)  do
    pw = ENV["TRAVIS"] ? nil : "foobared"
    {:type => Faye::Redis, :password => pw, :namespace => Time.now.to_i.to_s}
  end

  after do
    engine.disconnect
    redis = EM::Hiredis::Client.connect('localhost', 6379)
    redis.auth(engine_opts[:password])
    redis.flushall
  end

  it_should_behave_like "faye engine"
  it_should_behave_like "distributed engine"

  next if ENV["TRAVIS"]

  describe "using a Unix socket" do
    before { engine_opts[:socket] = "/tmp/redis.sock" }
    it_should_behave_like "faye engine"
  end
end

