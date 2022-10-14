module RuneRb::System::Errors
  # Raised when a Session is not received by a RuneRb::Game::World::Instance
  class SessionReceptionError < StandardError
    include RuneRb::Utils::Logging

    def initialize(type, expected, received)
      case type
      when :banned then super("#{received} is banned from this network!")
      when :op_code then super("Unrecognized operation code received in handshake!\t[Expected:] #{COLORS.green.bold(expected)}, [Received:] #{COLORS.red.bold(received)}")
      when :seed then super("Mismatched seed received in handshake!\t[Expected:] #{COLORS.green.bold(expected)}, [Received:] #{COLORS.red.bold(received)}")
      when :magic then super("Unexpected Magic received in handshake!\t[Expected:] #{COLORS.green.bold(expected)}, [Received:] #{COLORS.red.bold(received)}")
      when :username then super("Invalid Username in handshake!\t[Received:] #{COLORS.red.bold(received)}")
      when :password then super('Incorrect Password in handshake!')
      when :revision then super("Incompatible revision received in handshake!\t[Received:] #{COLORS.red.bold(received)}")
      else super("Unspecified SessionReceptionError! [Type: #{type.inspect}][Ex: #{COLORS.green.bold(expected)}][Rec: #{COLORS.red.bold(received)}]")
      end
    end
  end
end