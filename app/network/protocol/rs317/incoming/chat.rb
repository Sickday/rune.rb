module RuneRb::Network::RS317::PublicChatMessage
  include RuneRb::System::Log

  def parse(context)
    context.update(:chat, message: RuneRb::Game::Entity::ChatMessage.new(read_byte(false, :S), read_byte(false, :S), self))
  end
end