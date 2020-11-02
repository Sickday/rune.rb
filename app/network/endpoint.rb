module RuneRb::Network
  # Represents a host endpoint which accepts sockets and alerts them to populate their buffers via an internal nio selector
  class Endpoint
    include RuneRb::Types::Loggable

    # Called when a new Endpoint is created.
    def initialize(host = ENV['HOST'], port = ENV['PORT'])
      @selector = NIO::Selector.new
      @server = TCPServer.new(host || 'localhost', port || 43_594)
      @selector.register(@server, :r).value = proc { accept_peer }
      @peers = {}
      @clients = {}
      log RuneRb::COL.blue('[HOST]:' + RuneRb::COL.cyan("\t#{@server.addr[-1]}")),
          RuneRb::COL.blue('[PORT]:' + RuneRb::COL.cyan("\t#{@server.addr[1]}"))
    end

    # Spawns a new process and executes the selection loop within that process. *
    def deploy # *
      Parallel.in_processes(count: 1) do
        Concurrent::TimerTask.execute(execution_interval: 0.600) do
          begin
            flush
          rescue StandardError => e
            err 'An error occurred during flush cycle!', e.message
          end
        end
        loop { @selector.select { |monitor| monitor.value.call } }
      end
    end

    # De-registers a socket from the selector and removes it's reference from the internal client list.
    def deregister(peer, socket)
      log "De-registered socket for #{peer.ip}"
      @selector.deregister(socket)
      @peers[peer.ip].delete(peer)
    end

=begin
    def attach(client, to)
      # Make sure the world exists?
      # Make sure the world isn't full
      @world_list[to].receive(RuneRb::Entity::Context.new(client))
    end
=end

    private

    # Accepts a new socket connection via TCPServer#accept_nonblock and registers it with the Endpoint#clients hash. Sockets that are accepted are registered with the Endpoint#selector with an :r (readable) interest. The returned monitor object is passed a proc to execute `Endpoint#touch_clients` which is called when an interest is raised for the corresponding socket (it becomes readable/writable).
    def accept_peer
      socket = @server.accept_nonblock
      host = socket.peeraddr[-1]
      @peers[host] ||= []
      @peers[host] << RuneRb::Network::Peer.new(socket)
      @selector.register(socket, :r).value = proc { update_peers }
      log RuneRb::COL.green("Registered new socket for #{RuneRb::COL.cyan(host)}")
    end

    # Attempts to update clients registered with the Endpoint object. This is done by calling Client#receive_data on each client.**
    def update_peers
      @peers.each { |_ip, peers| peers.each(&:receive_data) }
    end

    def flush
      @peers.each { |_ip, peers| peers.each(&:flush) }
    end
  end
end

# * TODO: This is an insane idea. And probably won't go well. But if this is the route to go, the function should only contain the loop. The parallel process spawning should be done with a controller object or something to manage the processes.
# ** TODO: This could probably done in a better way, but it works fine for now.