module RuneRb::Network
  class Client
    using RuneRb::Patches::IntegerRefinements

    include RuneRb::Utils::Logging

    def initialize(socket, server)
      @ip = socket.remote_address
      @buffer = RuneRb::IO::Buffer.new('rw')
      @source = socket
      @server = server
      @closed = @source.closed?
      new_session
    end

    def last_heartbeat
      Time.now
    end

    def inspect
      RuneRb::LOGGER.colors.blue("[IP:] #{RuneRb::LOGGER.colors.cyan.bold(@ip)} || [ID:] #{RuneRb::LOGGER.colors.cyan.bold(@sigature)} || [UP:] #{RuneRb::LOGGER.colors.cyan.bold(up_time)}")
    end

    # The current up-time for the session.
    def up_time(formatted: true)
      up = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @session.duration[:time]).round(3).to_i
      formatted ? up.to_ftime : up
    end

    def update
      @buffer.push(@source.read_nonblock(5192))
    rescue IO::WaitReadable
      err 'Waiting for data'
    rescue EOFError
      err 'Reached End of Stream!'
      disconnect(:eof)
    end

    # Ends the session closing it's socket and updating the <@authentication.stage> to :LOGGED_OUT.
    # @param reason [Symbol] the reason for the disconnect. Exclusively used for logging purposes.
    def disconnect(reason = :manual)
      case reason
      when :eof then log 'Client disconnected after reaching the end of the stream.'
      when :manual then log 'Client disconnected manually.'
      when :reap then log 'Client connection reaped.'
      when :logout then log! RuneRb::LOGGER.colors.green.bold('Client session ended.')
      when :auth, :authentication then err 'Client disconnected during authentication.'
      when :io_error then err 'Client disconnected due to IO error.'
      when :handshake then err 'Client disconnected during handshake.'
      else err 'Client disconnected for unspecified reason!'
      end
    ensure
      @closed = true
      @source.close
      @server.deregister(@source)
    end

    def closed?
      @closed || @source.closed?
    end

    private

    Session = Struct.new(:seed, :credentials, :handshake, :duration, :login_stage, :login_attempts)

    def new_session
      @signature = Druuid.gen
      @session = Session.new((@signature & (0xFFFFFFFF / 2)), nil, nil,
                             { time: Process.clock_gettime(Process::CLOCK_MONOTONIC), start: Time.now },
                             :CONNECTION, 0)
    end
  end
end
