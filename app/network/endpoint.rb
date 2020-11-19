module RuneRb::Network
  # Represents a host endpoint which accepts sockets and alerts them to populate their buffers via an internal nio selector
  class Endpoint
    include RuneRb::Types::Loggable

    # Called when a new Endpoint is created.
    # @param host [String] the host for the Endpoint.
    # @param port [Integer, String] the port for the Endpoint.
    # @param world [RuneRb::Game::World] a World instance this endpoint can send authenticated Peers to.
    def initialize(world, host = ENV['HOST'], port = ENV['PORT'])
      @world = world
      @selector = NIO::Selector.new
      @server = TCPServer.new(host || 'localhost', port || 43_594)
      @selector.register(@server, :r).value = proc { accept_peer }
      @peers = {}
      @clients = {}
      log RuneRb::COL.blue('[HOST]:' + RuneRb::COL.cyan("\t#{@server.addr.last}")),
          RuneRb::COL.blue('[PORT]:' + RuneRb::COL.cyan("\t#{@server.addr[1]}"))
    end

    # Spawns a new process and executes the selection loop within that process. *
    def deploy
      raise 'No world registered to this endpoint!' unless @world

      Signal.trap('INT') do
        puts RuneRb::COL.magenta('Shutting down gracefully...')
        sleep(3)
        Kernel.exit
      end
      Parallel.in_processes(count: 1) do
        Concurrent::TimerTask.execute(execution_interval: 0.600) do
          begin
            @peers.values.each do |peer_list|
              peer_list.each do |peer|
                deregister(peer, peer.socket) unless peer.status[:active]
                peer.pulse
              end
            end
          rescue StandardError => e
            err 'An error occurred during pulse!', e.message
            puts e.backtrace
          end
        end
        loop { @selector.select { |monitor| monitor.value.call } }
      end
    end

    # De-registers a socket from the selector and removes it's reference from the internal client list.
    # @param peer [RuneRb::Network::Peer] the peer to deregister
    # @param socket [Socket] the socket object to deregister from selector.
    def deregister(peer, socket)
      @selector.deregister(socket)
      @peers[peer.ip].delete(peer)
      @world.release(peer.context) if peer.context
      log RuneRb::COL.green("De-registered socket for #{RuneRb::COL.cyan(peer.ip)}")
    end

    # Requests a context from the endpoint's world
    # @param peer [RuneRb::Network::Peer] the peer to request a context for
    def request_context(peer)
      raise 'No world registered to this endpoint!' unless @world

      @world.receive(peer)
    end

    private

    # Accepts a new socket connection via TCPServer#accept_nonblock and registers it with the Endpoint#clients hash. Sockets that are accepted are registered with the Endpoint#selector with an :r (readable) interest. The returned monitor object is passed a proc to execute `Endpoint#touch_clients` which is called when an interest is raised for the corresponding socket (it becomes readable/writable).
    def accept_peer
      socket = @server.accept_nonblock
      host = socket.peeraddr[-1]
      @peers[host] ||= []
      @peers[host] << RuneRb::Network::Peer.new(socket, self)
      @selector.register(socket, :r).value = proc { update_peers }
      log RuneRb::COL.green("Registered new socket for #{RuneRb::COL.cyan(host)}")
    end

    # Attempts to update peer streams via Peer#receive_data
    def update_peers
      @peers.each do |_ip, peers|
        peers.each do |peer|
          peer.status[:active] ? peer.receive_data : deregister(peer, peer.socket)
        end
      end
    end
  end
end

# * TODO: This is an insane idea. And probably won't go well. But if this is the route to go, the function should only contain the loop. The parallel process spawning should be done with a controller object or something to manage the processes.
# ** TODO: This could probably done in a better way, but it works fine for now.
