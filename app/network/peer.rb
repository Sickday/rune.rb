module RuneRb::Net
  class Peer < EM::Connection
    include RuneRb::Internal::Log

    include RuneRb::Net::LoginHelper
    include RuneRb::Net::FrameWriter
    include RuneRb::Net::FrameReader

    attr :ip, :id, :status, :socket, :context

    # Called after a new Peer object is initialized.
    def post_init
      @status = { auth: :PENDING_CONNECTION, active: true }
      _port, @ip = Socket.unpack_sockaddr_in(get_peername)
      @in = ''
      @out = []
      @id = Druuid.gen
    end

    # Registers a context to the peer
    # @param context [RuneRb::Entity::Context] the Context to register
    def register(context)
      @context = context
    end

    # Attaches the peer to an Endpoint object
    # @param endpoint [RuneRb::Net::Endpoint]
    def attach_to(endpoint)
      @endpoint = endpoint
      log 'Attached to Endpoint!' if RuneRb::DEBUG
    rescue StandardError => e
      err! 'An error occurred while attaching peer to Endpoint!'
      puts e
      puts e.backtrace
    end

    # Reads data into the Peer#in
    def receive_data(data)
      @in << data
      case @status[:auth]
      when :PENDING_CONNECTION
        read_connection
      when :PENDING_BLOCK
        read_block
      when :LOGGED_IN
        next_frame if @in.size >= 3
      else
        read_connection
      end
    end

    # This function is called every 600 ms. The client expects the player synchronization frame to be written every 600ms with any updated information included in the frame.
    def pulse
      @context.pre_pulse
      write(:sync, context: @context) if @status[:auth] == :LOGGED_IN && @status[:active] && @context.world
      @context.post_pulse
    rescue StandardError => e
      err! 'An error occurred during Peer pulse!', e, e.backtrace
    end

    def unbind
      @status[:active] = false
      @status[:auth] = :LOGGED_OUT
      @context&.world&.release(@context)
    end
  end
end