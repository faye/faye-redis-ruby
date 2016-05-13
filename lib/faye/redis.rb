require 'em-hiredis'
require 'em-hiredis-sentinel'
require 'multi_json'

module Faye
  class Redis

    DEFAULT_HOST     = 'localhost'
    DEFAULT_PORT     = 6379
    DEFAULT_DATABASE = 0
    DEFAULT_GC       = 60
    LOCK_TIMEOUT     = 120

    def self.create(server, options)
      new(server, options)
    end

    def initialize(server, options)
      @server  = server
      @options = options

      init if EventMachine.reactor_running?
    end

    def init
      return if @redis

      uri    = @options[:uri]       || nil
      host   = @options[:host]      || DEFAULT_HOST
      port   = @options[:port]      || DEFAULT_PORT
      db     = @options[:database]  || DEFAULT_DATABASE
      auth   = @options[:password]  || nil
      gc     = @options[:gc]        || DEFAULT_GC
      @ns    = @options[:namespace] || ''
      socket = @options[:socket]    || nil
      sentinels = @options[:sentinels] || nil
      master_name = @options[:master_name] || nil

      if sentinels && master_name
        @redis = EventMachine::Hiredis::Sentinel::RedisClient.new(sentinels: sentinels,
                                                                  master_name: master_name).connect
        @server.debug 'Redis has been initialized with sentinels'
      elsif uri
        @redis = EventMachine::Hiredis.connect(uri)
      elsif socket
        @redis = EventMachine::Hiredis::Client.new(socket, nil, auth, db).connect
      else
        @redis = EventMachine::Hiredis::Client.new(host, port, auth, db).connect
      end
      @subscriber = @redis.pubsub

      @message_channel = @ns + '/notifications/messages'
      @close_channel   = @ns + '/notifications/close'

      @subscriber.subscribe(@message_channel)
      @subscriber.subscribe(@close_channel)
      @subscriber.on(:message) do |topic, message|
        empty_queue(message) if topic == @message_channel
        @server.trigger(:close, message) if topic == @close_channel
      end

      @gc = EventMachine.add_periodic_timer(gc, &method(:gc))
    end

    def disconnect
      return unless @redis
      @subscriber.unsubscribe(@message_channel)
      @subscriber.unsubscribe(@close_channel)
      EventMachine.cancel_timer(@gc)
    end

    def create_client(&callback)
      init
      client_id = @server.generate_id
      @redis.zadd(@ns + '/clients', 0, client_id) do |added|
        next create_client(&callback) if added == 0
        @server.debug 'Created new client ?', client_id
        ping(client_id)
        @server.trigger(:handshake, client_id)
        callback.call(client_id)
      end
    end

    def client_exists(client_id, &callback)
      init
      cutoff = get_current_time - (1000 * 1.6 * @server.timeout)

      @redis.zscore(@ns + '/clients', client_id) do |score|
        callback.call(score.to_i > cutoff)
      end
    end

    def destroy_client(client_id, &callback)
      init
      @redis.zadd(@ns + '/clients', 0, client_id) do
        @redis.smembers(@ns + "/clients/#{client_id}/channels") do |channels|
          i, n = 0, channels.size
          next after_subscriptions_removed(client_id, &callback) if i == n

          channels.each do |channel|
            unsubscribe(client_id, channel) do
              i += 1
              after_subscriptions_removed(client_id, &callback) if i == n
            end
          end
        end
      end
    end

    def after_subscriptions_removed(client_id, &callback)
      @redis.del(@ns + "/clients/#{client_id}/messages") do
        @redis.zrem(@ns + '/clients', client_id) do
          @server.debug 'Destroyed client ?', client_id
          @server.trigger(:disconnect, client_id)
          @redis.publish(@close_channel, client_id)
          callback.call if callback
        end
      end
    end

    def ping(client_id)
      init
      timeout = @server.timeout
      return unless Numeric === timeout

      time = get_current_time
      @server.debug 'Ping ?, ?', client_id, time
      @redis.zadd(@ns + '/clients', time, client_id)
    end

    def subscribe(client_id, channel, &callback)
      init
      @redis.sadd(@ns + "/clients/#{client_id}/channels", channel) do |added|
        @server.trigger(:subscribe, client_id, channel) if added == 1
      end
      @redis.sadd(@ns + "/channels#{channel}", client_id) do
        @server.debug 'Subscribed client ? to channel ?', client_id, channel
        callback.call if callback
      end
    end

    def unsubscribe(client_id, channel, &callback)
      init
      @redis.srem(@ns + "/clients/#{client_id}/channels", channel) do |removed|
        @server.trigger(:unsubscribe, client_id, channel) if removed == 1
      end
      @redis.srem(@ns + "/channels#{channel}", client_id) do
        @server.debug 'Unsubscribed client ? from channel ?', client_id, channel
        callback.call if callback
      end
    end

    def publish(message, channels)
      init
      @server.debug 'Publishing message ?', message

      json_message = MultiJson.dump(message)
      channels     = Channel.expand(message['channel'])
      keys         = channels.map { |c| @ns + "/channels#{c}" }

      @redis.sunion(*keys) do |clients|
        clients.each do |client_id|
          queue = @ns + "/clients/#{client_id}/messages"

          @server.debug 'Queueing for client ?: ?', client_id, message
          @redis.rpush(queue, json_message)
          @redis.publish(@message_channel, client_id)

          client_exists(client_id) do |exists|
            @redis.del(queue) unless exists
          end
        end
      end

      @server.trigger(:publish, message['clientId'], message['channel'], message['data'])
    end

    def empty_queue(client_id)
      return unless @server.has_connection?(client_id)
      init

      key = @ns + "/clients/#{client_id}/messages"

      @redis.multi
      @redis.lrange(key, 0, -1)
      @redis.del(key)
      @redis.exec.callback do |json_messages, deleted|
        next unless json_messages
        messages = json_messages.map { |json| MultiJson.load(json) }
        @server.deliver(client_id, messages)
      end
    end

  private

    def get_current_time
      (Time.now.to_f * 1000).to_i
    end

    def gc
      timeout = @server.timeout
      return unless Numeric === timeout

      with_lock 'gc' do |release_lock|
        cutoff = get_current_time - 1000 * 2 * timeout
        @redis.zrangebyscore(@ns + '/clients', 0, cutoff) do |clients|
          i, n = 0, clients.size
          next release_lock.call if i == n

          clients.each do |client_id|
            destroy_client(client_id) do
              i += 1
              release_lock.call if i == n
            end
          end
        end
      end
    end

    def with_lock(lock_name, &block)
      lock_key     = @ns + '/locks/' + lock_name
      current_time = get_current_time
      expiry       = current_time + LOCK_TIMEOUT * 1000 + 1

      release_lock = lambda do
        @redis.del(lock_key) if get_current_time < expiry
      end

      @redis.setnx(lock_key, expiry) do |set|
        next block.call(release_lock) if set == 1

        @redis.get(lock_key) do |timeout|
          next unless timeout

          lock_timeout = timeout.to_i(10)
          next if current_time < lock_timeout

          @redis.getset(lock_key, expiry) do |old_value|
            block.call(release_lock) if old_value == timeout
          end
        end
      end
    end
  end
end
