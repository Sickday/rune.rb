module RuneRb::Network::Helpers::Authentication

  def valid_connection?(type)
    RuneRb::Network::CONNECTION_TYPES.value?(type)
  end

  def valid_handshake?(block)
    return false unless valid_op_code?(block[:op_code])
    return false unless valid_protocol?(block[:protocol])
    return false unless valid_magic?(block[:magic])

    true
  end
  # Performs authentication on the passed socket.
  # @param socket [TCPSocket] the socket to authenticate.
  def authenticate(client)
    #profile = RuneRb::Database::PlayerProfile.fetch_profile(session.handshake[:credentials].username)
    #return unless valid?(session, profile, target, profile.nil?)

    #target.receive(session, profile || RuneRb::Database::PlayerProfile.register(session.sig.to_s, session.handshake[:credentials]),
    #               first_login: profile.nil?)
    #session.stage = :logged_in
  end

  private

  # Checks if a session's login block op_code is valid.
  # @param op_code [Integer] the integer
  # @return [Boolean] is the op_code valid?
  # @api private
  def valid_op_code?(op_code)
    unless [RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE], RuneRb::Network::CONNECTION_TYPES[:GAME_RECONNECT]].include?(op_code)
      err "Unrecognized Connection type! [Expected: [16, 18], Received: #{op_code}]"
      return false
    end
    true
  end

  # Checks if a session's seed is the same as the client's seed.
  # @param handshake_seed [Struct] the session's seed
  # @param session_seed [Hash] the session's seed data
  # @return [Boolean] is the seed valid?
  # @api private
  def valid_seed?(session_seed, handshake_seed)
    unless session_seed == handshake_seed
      err "Seed Mismatch! [Expected: #{session_seed}, Received: #{handshake_seed}]"
      return false
    end
    true
  end

  # Checks if a session's magic is the same as the client's magic.
  # @param magic [Integer] the magic
  # @return [Boolean] is the magic valid?
  # @api private
  def valid_magic?(magic)
    unless magic == 0xff
      err "Unexpected Magic! [Expected: 255, Received: #{magic}]"
      return false
    end
    true
  end

  # Checks if a session's revision is supported by the application.
  # @param protocol [Integer] the protocol received during handshake.
  # @api private
  def valid_protocol?(protocol)
    unless RuneRb::Network::PROTOCOL == protocol
      err "Unsupported Protocol! [Expected: #{RuneRb::Network::PROTOCOL}, Received: #{protocol}]"
      return false
    end
    true
  end

  # Checks the credentials of the credentials_block for a session
  # @param credential_data [Struct] the credential data received during handshake.
  # @param profile [RuneRb::Database::Player::Profile] the profile fetched by username
  # @return [Boolean] are the credentials valid?
  # @api private
  def valid_credentials?(credential_data, profile)
    unless credential_data.username.length >= 1 && !RuneRb::Database::SystemBannedNames.check(credential_data.username)
      log COLORS.red("Invalid Username for #{COLORS.yellow(credential_data.username)}")
      return false
    end

    unless profile.password == credential_data.password
      log COLORS.red("Invalid Password for #{COLORS.yellow(profile.username.capitalize)}!")
      return false
    end

    true
  end

  # Validate the banned status of the profile
  # @param profile [RuneRb::Database::Player::Profile]
  def valid_banned_status?(profile)
    unless profile.attributes.banned == false
      log COLORS.magenta("#{COLORS.red.bold(profile.username)} is banned from this network!")
      return false
    end
    true
  end

  # Validates the availability of the requested world
  # @param world [RuneRb::Game::World::Instance] the world to check.
  # @return [Boolean] is the world online?
  def valid_availability?(world)
    if world.closed?
      log COLORS.red.bold("Requested world with signature #{world.properties.signature} is offline!")
      return false
    end
    true
  end

  # Validate the capacity of the requested world
  # @param world [RuneRb::Game::World::Instance] the world to check.
  # @return [Boolean] is the capacity valid?
  def valid_capacity?(world)
    unless (world.players.length + 1) < world.properties.max_contexts
      log! COLORS.red.bold('World is full and cannot receive any more contexts!')
      return false
    end
    true
  end

  # Validate the profile by ensure no other contexts are using this profile.
  # @param profile [RuneRb::Database::PlayerProfile] the profile to validate
  # @param world [RuneRb::Game::World::Instance] the world to check.
  # @return [Boolean] is the profile valid?
  def valid_profile?(profile, world)
    active = world.players.detect { |player| player.profile == profile }
    unless active.nil?
      log! COLORS.red("Conflicting Context! Object: [profile: #{COLORS.yellow.bold(profile.username)}]")
      active.logout
      return false
    end
    true
  end
end
