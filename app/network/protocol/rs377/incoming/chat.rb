module RuneRb::Network::RS377::PublicChatMessage
  include RuneRb::System::Log

  def parse(context)
    context.update(:chat, message: RuneRb::Game::Entity::ChatMessage.new(read_byte(false, :ADD), read_byte(false, :NEGATE), self))
  end
end