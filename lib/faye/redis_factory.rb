module Faye
  class RedisFactory

    DEFAULT_HOST     = '0.0.0.0'
    DEFAULT_PORT     = 6379
    DEFAULT_DATABASE = 0

    def initialize(options)
      @options = options
    end

    def call
      uri    = @options[:uri]      || nil
      socket = @options[:socket]   || nil
      host   = @options[:host]     || DEFAULT_HOST
      port   = @options[:port]     || DEFAULT_PORT
      auth   = @options[:password] || nil
      db     = @options[:database] || DEFAULT_DATABASE

      if uri
        EventMachine::Hiredis.connect(uri)
      elsif socket
        EventMachine::Hiredis::Client.new(socket, nil, auth, db).connect
      else
        EventMachine::Hiredis::Client.new(host, port, auth, db).connect
      end
    end

  end
end
