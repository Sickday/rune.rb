module RuneRb::Errors
  class LoginError < StandardError
    attr :type

    def initialize(type, expected, offender)
      @type = type
      case @type
      when :ServerHalfMismatch
        super("Server key mismatch! Expected: #{expected} Got: #{offender}")
      when :MagicMismatch
        super("Magic mismatch! Expected #{expected} Got: #{offender}")
      when :LoginOpcode
        super("Invalid Login OpCode! Expected #{expected} Got: #{offender}")
      end
    end
  end
end