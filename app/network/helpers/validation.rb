module RuneRb::Network::Helpers::Validation
  class << self
    include RuneRb::Utils::Logging

    # Validates the passed parameters according to the options.
    # @param buffer [Buffer] the buffer to validate against.
    # @param operation [String] the operation to validate.
    # @param params [Hash] a map of parameters to validate.
    # @todo implement a ValidationError type to be raised when a validation fails.
    def validate(buffer, operation, params = {})
      return false unless valid_mode?(buffer, operation)
      return false unless valid_access?(buffer, params[:bit_access]) if buffer.mode.include?('w') && params[:bit_access]
      return false unless valid_mutation?(params[:mutation]) if params[:mutation]
      return false unless valid_order?(params[:order]) if params[:order]

      true
    end

    # Reads data directly from an IO stream.
    # @param io [Socket, IO] the IO object to read from.
    # @param length [Integer] the amount of data to read
    # @param buffer [Buffer] the buffer to read to.
    def from_io(io, length, buffer)
      raise "Closed IO" if io.closed?

      io.read_nonblock(length, buffer.data)
    end

    private

    # Validates the current access mode for the write channel.
    # @param buffer [Buffer] the buffer to validate against.
    # @param required [Boolean] the access type required for the operation.
    def valid_access?(buffer, required)
      unless buffer.bit_access == required
        err "Invalid access for operation! #{required} access is required for operation!"
        return false
      end
      true
    end

    # Validates the operation with the current mode of the message.
    # @param buffer [Buffer] the buffer to validate against.
    # @param operation [String] the operation to validate.
    def valid_mode?(buffer, operation)
      return false if buffer.mode == 'r' && /(?i)\bpeek_write|write/.match?(operation)
      return false if buffer.mode == 'w' && /(?i)\bpeek_read|read/.match?(operation)

      true
    end

    # Validates the byte mutation for the operation
    # @param mutation [String] the mutation that will be applied in the operation.
    def valid_mutation?(mutation)
      unless RuneRb::Network::BYTE_MUTATIONS.include?(mutation)
        err "Unrecognized mutation! #{mutation}"
        return false
      end
      true
    end

    # Validates the byte order to read for the operation
    # @param order [String] the order in which to read bytes in the operation.
    def valid_order?(order)
      unless RuneRb::Network::BYTE_ORDERS.match?(order)
        err "Unrecognized byte order! #{order}"
        return false
      end
      true
    end
  end
end
