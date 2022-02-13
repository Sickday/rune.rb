module RuneRb::Game::Entity::Helpers::Looks

  def to_mob(id)
    @profile.appearance.update(mob_id: id)
  end

  def from_mob
    @profile.appearance.update(mob_id: -1)
  end

  def to_head(id)
    @profile.appearance.update(head_icon: id)
  end

  private

  # Reads and parses an appearance from a message.
  # @param message [RuneRb::Network::Message] the message to read from
  def parse_appearance(message)
    @profile.appearance.update(gender: message.read(type: :byte, mutation: :STD),
                               head: message.read(type: :byte, mutation: :STD),
                               beard: message.read(type: :byte, mutation: :STD),
                               chest: message.read(type: :byte, mutation: :STD),
                               arms: message.read(type: :byte, mutation: :STD),
                               hands: message.read(type: :byte, mutation: :STD),
                               legs: message.read(type: :byte, mutation: :STD),
                               feet: message.read(type: :byte, mutation: :STD),
                               hair_color: message.read(type: :byte, mutation: :STD),
                               torso_color: message.read(type: :byte, mutation: :STD),
                               leg_color: message.read(type: :byte, mutation: :STD),
                               feet_color: message.read(type: :byte, mutation: :STD),
                               skin_color: message.read(type: :byte, mutation: :STD))
  end
end
