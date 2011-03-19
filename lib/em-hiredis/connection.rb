module EM::Hiredis
  class Connection < EM::Connection
    include EventEmitter

    COMMAND_DELIMITER  = "\r\n"
    STRING_SIZE_METHOD = String.instance_methods.include?(:bytesize) ? :bytesize : :size


    def initialize(host, port)
      super
      @host, @port = host, port
    end

    def connection_completed
      EM::Hiredis.logger.info("Connected to Redis (#{@host}:#{@port})")
      @reader = ::Hiredis::Reader.new
      emit(:connected)
    end

    def receive_data(data)
      EM::Hiredis.logger.debug("Got raw: #{data.inspect}")
      @reader.feed(data)
      until (reply = @reader.gets) == false
        EM::Hiredis.logger.debug("Raw parsed to: #{reply.inspect}")
        emit(:message, reply)
      end
    end

    def unbind
      EM::Hiredis.logger.info("Disconnected from Redis (#{@host}:#{@port})")
      emit(:closed)
    end

    def send_command(sym, *args)
      EM::Hiredis.logger.debug("Sending: #{[sym, *args].join(' ')}")
      EM::Hiredis.logger.debug("Sending raw: #{command(sym, *args)}")
      send_data(command(sym, *args))
    end


    def command(*args)
      command = ["*#{args.size}"]

      args.each do |arg|
        arg = arg.to_s
        command << "$#{string_size arg}"
        command << arg
      end

      command.join(COMMAND_DELIMITER) + COMMAND_DELIMITER
    end
    protected :command

    def string_size(string)
      string.to_s.send(STRING_SIZE_METHOD)
    end
    protected :string_size

  end
end
