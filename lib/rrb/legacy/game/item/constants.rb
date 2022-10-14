module RuneRb::Game::Item::Constants
  # @!attribute [r] PLACEHOLDER
  # @return [RuneRb::Game::Item::Stack] the placeholder item stack.
  PLACEHOLDER = RuneRb::Game::Item::Stack.new(-1, 0).freeze

  # @!attribute [r] MAX_SIZE
  # @return [Integer] the max item size
  MAX_SIZE = (2**31 - 1)
end