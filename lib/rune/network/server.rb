module RuneRb::Network
  class Server < RuneRb::Component
    include RuneRb::Utils::Logging

    # @!attribute [r] gateway
    # @return [RuneRb::Network::Gateway] the gateway
    attr :gateway

    # @!attribute [r] closed
    # @return [Boolean] determines whether the server is in a closed state.
    attr :closed

    # @!attribute [r] signature
    # @return [Integer, Symbol, String] the signature for the server
    attr :signature

    # Closes the Server
    def shutdown
      @clients.each_value { |client| client.disconnect(:manual) }
      log! "Closed #{@clients.length} clients."
    ensure
      @server.close
      @closed = true
    end

    # Check if the server is in a closed state.
    # @return [Boolean] is the server closed?
    def closed?
      @server.closed? || @closed
    end

    # Process the Server.
    def process
      select
      reap
    end

    # Create workers to handle sockets and construct a server socket.
    def setup
      @signature = {}.tap do |sig|
        sig[:raw] = Druuid.gen
        sig[:seed] = sig[:raw] & (0xFFFFFFFF / 2)
      end
      @clients ||= {}
      @server ||= TCPServer.new(ENV['RRB_NET_HOST'] || 'localhost', ENV['RRB_NET_PORT'].to_i || 43_594)
      log "Listening @ #{@server.inspect}"

      @selector = NIO::Selector.new(:epoll)
      @selector.register(@server, :r).value = Fiber.new do
        loop do
          accept unless closed?
        rescue StandardError => e
          err 'An error occurred during the Server#accept operation!', e.message, e.backtrace&.join("\n")
        ensure
          Fiber.yield unless closed?
        end
      end
    end

    # Sets a gateway object for the server to use to authenticate and balance connections.
    def use_gateway(gateway)
      @gateway = gateway
      @gateway.register(self)
    end

    # Deregisters a socket from the server selector.
    def deregister(socket)
      @selector.deregister(socket)
      @clients.delete(socket)
    end

    # Registers a socket to the server selector.
    def register(socket)
      @selector.register(socket, :r).value = Fiber.new do
        loop do
          update(socket) unless socket.closed? || closed?
        ensure
          Fiber.yield unless closed?
        end
      end
      @clients[socket] = RuneRb::Network::Client.new(socket, self)
      log! "Registered new client #{@clients[socket]}!"
    end

    private

    # Accept new sockets and attempt to authenticate them via the <@gateway>
    def accept
      socket = @server.accept_nonblock(exception: false)
      return unless socket.is_a?(TCPSocket)

      log! 'Gateway is registered' if @gateway
      @gateway ? @gateway.receive(socket) : register(socket)
    end

    # Updates a client
    # @param socket [TCPSocket] the client's socket.
    def update(socket)
      @clients[socket].update
    end

    # Selects readable sockets and processes them accordingly.
    def select
      @selector.select(0.001)&.each { |monitor| monitor.value.resume }
    end

    # Reap closed connections.
    def reap
      @clients.values
              .select { |client| client.closed? || @clients.key(client).closed? } # || client.last_heartbeat >= ENV['RRB_NET_HEARTBEAT_INTERVAL'].to_i }
              .each { |client| client.disconnect(:reaped) }
    end
  end
end
