module RuneRb::Entity
  # A entity Message is the object created when an Entity chats via the chatbox.
  class Message
    # @return [String] the text contained within the Message
    attr :text

    # @return [Integer] the effects of the Message
    attr :effects

    # @return [Integer] the colors of the Message
    attr :colors

    # @return [Integer] the rights of the Context for which the Message will belong.
    attr :rights

    # Called when a new entity Message is created.
    # @param text [String] The text contained within the Message.
    # @param effects [Integer] the effects the Message will have.
    # @param colors [Integer] the colors the Message will have.
    # @param rights [Integer] the rights of the context
    def initialize(effects, colors, text, rights)
      @text = text
      @effects = effects
      @colors = colors
      @rights = rights
    end
  end
end