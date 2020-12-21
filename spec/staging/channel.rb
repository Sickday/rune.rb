class Channel

  # @return [Boolean] is the channel closed?
  attr :closed

  # Called when a Generic channel is created.
  # @param socket_or_io [IPSocket, IO] the socket or IO object the channel will wrap
  # @todo Testcase: Test that proper mode is applied based on mode string
  def initialize(socket_or_io = nil)
    source(socket_or_io)
  end

  # Requests a message to be read from the source IO for the channel.
  def request(cipher, task: Async::Task.current)
    raise 'Channel is closed!' if @closed

    task.async do |sub|
      # Retrieve and decode the next readable message from the source.
      message = decode(next_message, cipher)

      # Parse the decoded message.
      process(message, task: sub)

      # Add the frame to the Channel's history.
      record(:read, message)
    rescue Async::Wrapper::WaitError
      task.yield
    rescue StandardError => e
      puts 'An error occurred while requesting the next readable message!'
      puts e
      puts e.backtrace
      # dump_history
    rescue IO::EAGAINWaitReadable
      nil
    rescue EOFError
      err 'Reached EOF!' if RuneRb::GLOBAL[:RRB_DEBUG]
      close
    end
  end

  # Submits a message to the source IO for the channel.
  # @param message [Frame] the message to write to the io.
  def submit(message, cipher = nil, task: Async::Task.current)
    raise 'Channel is closed!' if @closed

    task.async do
      # Write the encoded message to the source io.
      @source.write_nonblock(message.is_a?(RuneRb::Network::Frame) ? encode(message, cipher).compile : message)

      # Add the frame to the Channel's history
      record(:write, message)
    rescue StandardError => e
      puts 'An error occurred while submitting the current writable message!'
      puts e
      puts e.backtrace
      # dump_history
      task.yield
    end
  end

  # Close the channel
  def close
    @closed = true
  end

  private

  # Reads the next parseable frame from Session#in, then attempts to handle the frame accordingly.
  # @return [Message] t
  def next_message
    header = {}.tap do |data|
      data[:op_code] = @socket.read_nonblock(1).next_byte
      data[:length] = FRAME_SIZES[data[:op_code]] == -1 ? @socket.read_nonblock(1).next_byte : FRAME_SIZES[data[:op_code]]
    end
    log! RuneRb::COL.green("Read Header: #{header.inspect}") if RuneRb::GLOBAL[:RRB_DEBUG]

    body = NIO::ByteBuffer.new(header[:length]).clear
    body.read_from(@source)
    RuneRb::Network::Message.new('r', header, body)
  end

  # Encodes a message using a cipher.
  # @param message [RuneRb::Network::Frame] the message to encode
  # @param cipher [Struct] the cipher that will be used to encode the message.
  def encode(message, cipher)
    raise 'Invalid cipher!' unless cipher

    log! RuneRb::COL.green("Encoded frame: #{RuneRb::COL.yellow.bold(message.inspect)}") if RuneRb::GLOBAL[:RRB_DEBUG]
    message.header[:op_code] += cipher[:encryptor].next_value & 0xFF
    message
  end

  # Decodes a message using a cipher.
  # @param message [RuneRb::Network::Frame] the message to decode.
  # @param cipher [Struct] the cipher that will be used to decode the message.
  def decode(message, cipher)
    raise 'Invalid cipher' unless cipher

    message.header[:op_code] -= cipher[:decryptor].next_value & 0xFF
    message.header[:op_code] = message.header[:op_code] & 0xFF
    message.header[:length] = RuneRb::Network::FRAME_SIZES[message.header[:op_code]]
    log! RuneRb::COL.green("Decoded message: #{RuneRb::COL.yellow.bold(message.inspect)}") if RuneRb::GLOBAL[:RRB_DEBUG]
    message
  end

  # Records a frame to the channel history
  # @param type [Symbol] the type of update to apply to the history
  # @param message [Frame] the frame to update the history with.
  # @todo Testcase: Test that read/write record is accurately called to ensure no data is read or written without being recorded in history first.
  def record(type, message)
    @history ||= { read: '', wrote: '' }
    @history[:wrote] << message.dup.compile if type == :write
    @history[:read] << message.dup.peek if type == :read
  end

  # Update the channel io source.
  # @param io [IO, IPSocket] the io object the channel will attach to.
  # @todo Testcase: Test that the socket is an IO or Socket.
  def source(io)
    raise 'Invalid source IO' unless io.is_a?(IO) || io.is_a?(IPSocket)

    @source = io
  end
end