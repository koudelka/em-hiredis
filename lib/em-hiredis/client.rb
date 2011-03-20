module EM::Hiredis
  class Client
    include EventEmitter
    include EM::Deferrable

    PUBSUB_MESSAGES = %w{message pmessage}.freeze
    BOOLEAN_RESPONSES = [
      :exists,
      :expire,
      :expireat,
      :hdel,
      :hexists,
      :hset,
      :hsetnx,
      :move,
      :persist,
      :renamenx,
    ]

    SPECIAL_CASES = {}

    def self.connect(args)
      new(args)
    end

    def initialize(args)
      @host = args[:host] || 'localhost'
      @port = args[:port] || 6379
      @reconnect_secs = args[:reconnect_secs] || 1
      @subs, @psubs = [], []
      @defs = []
      @connection = EM.connect(@host, @port, Connection, @host, @port)
      @state = :disconnected # can be :connected, :reconnecting, :pubsub or :disconnected

      @connection.on(:closed) do
        if @state == :connected
          @defs.each { |d| d.last.fail("Redis disconnected (#{@host}:#{@port}), reconnecting in #{@reconnect_secs} seconds.") }
          @defs = []
          @deferred_status = nil
          reconnect
        else
          EM.add_timer(@reconnect_secs) { reconnect }
        end
      end

      @connection.on(:connected) do
        state_was = @state
        @state = :connected

        select(@db) if @db
        @subs.each { |s| method_missing(:subscribe, s) }
        @psubs.each { |s| method_missing(:psubscribe, s) }

        emit(:reconnected) if state_was == :reconnecting
        succeed
      end

      @connection.on(:message) do |reply|
        if @status == :pubsub
          kind, subscription, d1, d2 = *reply
          EM::Hiredis.logger.debug("PubSub mode reply: #{reply.inspect}")

          case kind.to_sym
            when :message
              emit(:message, subscription, d1)
            when :pmessage
              emit(:pmessage, subscription, d1, d2)
          end
        else
          raise "Replies out of sync: #{reply.inspect}" if @defs.empty?

          command, deferred = @defs.shift

          reply = reply > 0  if BOOLEAN_RESPONSES.include?(command)

          EM::Hiredis.logger.debug("Normal mode reply: #{command} -> #{reply}")

          if RuntimeError === reply
            deferred.fail(reply) if deferred
          else
            deferred.succeed(reply) if deferred
          end
        end
      end
    end

    # Indicates that commands have been sent to redis but a reply has not yet
    # been received.
    #
    # This can be useful for example to avoid stopping the
    # eventmachine reactor while there are outstanding commands
    #
    def pending_commands?
      @state == :connected && @defs.size > 0
    end

    #
    # Commands that need special treatment before being sent.
    #

    def self.special_case(sym, &block)
      SPECIAL_CASES[sym] = block
    end

    special_case :sort do |key, options|
      [key] + \
        options.collect do |option, value|
          case option.to_sym
            when :get
              [*value].collect { |get| ['get', get] }
            when :by, :limit, :store
              [option, value]
            when :order
              value
            else
             option
          end
        end
    end

    special_case :select do |db|
      @db = db
    end

    special_case :subscribe do |channel|
      @subs << channel
      channel
    end

    special_case :subscribe do |channel|
      @subs << channel
      channel
    end

    special_case :unsubscribe do |channel|
      @subs.delete(channel)
    end

    special_case :psubscribe do |channel|
      @psubs << channel
      channel
    end

    special_case :punsubscribe do |channel|
      @psubs.delete(channel)
    end


    def method_missing(sym, *args, &block)
      sym = sym.to_s.downcase.to_sym

      args = SPECIAL_CASES[sym].call(*args) if SPECIAL_CASES[sym]
      args = [*args].collect { |o| o.respond_to?(:flatten) ? o.flatten : o }.flatten # necessary to flatten both hashes and arrays

      deferred = EM::DefaultDeferrable.new
      # Shortcut for defining the callback case with just a block
      deferred.callback(&block) if block_given?

      if @state == :connected
        @connection.send_command(sym, *args)
        @defs.push([sym, deferred])
      else
        callback do
          @connection.send_command(sym, *args)
          @defs.push([sym, deferred])
        end
      end

      deferred
    end


    def reconnect
      EM::Hiredis.logger.debug("Trying to reconnect to Redis (#{@host}:#{@port})")
      @state = :reconnecting
      @connection.reconnect @host, @port
    end
    private :reconnect

  end
end
