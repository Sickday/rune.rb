module RuneRb::Network::RS317::WindowFocusMessage
  include RuneRb::System::Log

  def parse(_)
    focused = read_byte
    log RuneRb::GLOBAL[:COLOR].blue("Client Focus: #{RuneRb::GLOBAL[:COLOR].cyan(focused.positive? ? '[Focused]' : '[Unfocused]')}!") if RuneRb::GLOBAL[:DEBUG]
  end
end