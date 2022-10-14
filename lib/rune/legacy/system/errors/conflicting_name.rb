module RuneRb::System::Errors
  # Raised when a name conflict occurs.
  class ConflictingNameError < StandardError
    include RuneRb::Utils::Logging

    def initialize(type, received)
      case type
      when :banned_name then super("Appended banned name already exists in database!\t[Received:] #{COLORS.red.bold(received)}")
      when :username then super("A profile with this Username already exists in database!\t[Received:] #{COLORS.red.bold(received)}")
      else super("Unspecified ConflictingNameError! [Type: #{type.inspect}][Rec: #{COLORS.red.bold(received)}]")
      end
    end
  end
end
