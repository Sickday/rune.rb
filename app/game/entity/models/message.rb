module RuneRb::Game::Entity
  # A entity Message is the object created when an Entity chats via the chatbox.
  class Message
    # @return [String] the text contained within the Message
    attr :text

    # @return [Integer] the effects of the Message
    attr :effects

    # @return [Integer] the colors of the Message
    attr :colors

    # Called when a new entity Message is created.
    # @param text [String] The text contained within the Message.
    # @param effects [Integer] the effects the Message will have.
    # @param colors [Integer] the colors the Message will have.
    def initialize(effects, colors, text)
      @text = text
      @effects = effects
      @colors = colors
    end

    def self.from_frame(frame)
      Message.new(frame.read_byte(false, :S),
                  frame.read_byte(false, :S),
                  frame.read_bytes_reverse(frame.header[:length] - 2, :A))
    end
  end
end