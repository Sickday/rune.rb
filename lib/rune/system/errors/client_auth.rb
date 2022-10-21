module RuneRb::Errors
  # Raised when a Client is unable to be received due to an error.
  class ClientAuthenticationError < StandardError

    # Constructs a ClientReceptionError
    # @param type [Symbol] the type of reception error
    # @param expected [Object] the expected object
    # @param received [Object] the received object
    def initialize(type, expected, received)
      case type
      when :banned then super("#{received} is banned from this network!")
      when :op_code then super("Unrecognized operation code received in handshake!\t[Expected:] #{RuneRb::LOGGER.colors.green.bold(expected)}, [Received:] #{RuneRb::LOGGER.colors.red.bold(received)}")
      when :seed then super("Mismatched seed received in handshake!\t[Expected:] #{RuneRb::LOGGER.colors.green.bold(expected)}, [Received:] #{RuneRb::LOGGER.colors.red.bold(received)}")
      when :magic then super("Unexpected Magic received in handshake!\t[Expected:] #{RuneRb::LOGGER.colors.green.bold(expected)}, [Received:] #{RuneRb::LOGGER.colors.red.bold(received)}")
      when :username then super("Invalid Username in handshake!\t[Received:] #{RuneRb::LOGGER.colors.red.bold(received)}")
      when :password then super('Incorrect Password in handshake!')
      when :revision then super("Incompatible revision received in handshake!\t[Received:] #{RuneRb::LOGGER.colors.red.bold(received)}")
      else super("Unspecified SessionReceptionError! [Type: #{type}][Ex: #{RuneRb::LOGGER.colors.green.bold(expected)}][Rec: #{RuneRb::LOGGER.colors.red.bold(received)}]")
      end
    end
  end
end
