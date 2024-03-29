module RuneRb::Utils::Helpers::Gateway
  include RuneRb::Utils::Logging

  # Attempts to authenticate a session for a specific world target
  # @param session [RuneRb::Network::Session] the session to authenticate
  # @param target [RuneRb::Game::World::Instance] the target world instance
  def authenticate(session, target)
    profile = RuneRb::Database::PlayerProfile.fetch_profile(session.handshake[:credentials].username)
    return unless valid?(session, profile, target, profile.nil?)

    target.receive(session, profile || RuneRb::Database::PlayerProfile.register(session.sig.to_s, session.handshake[:credentials]),
                   first_login: profile.nil?)
    session.stage = :logged_in
  end

  private

  # Checks if a session, it's requested profile, and the world requested are all valid
  # @param session  [RuneRb::Network::Session] the session to validate
  # @param profile [RuneRb::Database::PlayerProfile] the requested profile
  # @param target [RuneRb::Game::World::Instance] the target world instance
  # @param first_time [Boolean] is this a first time auth request?
  def valid?(session, profile, target, first_time)
    return reject(:BANNED_ACCOUNT, session) unless first_time || valid_banned_status?(profile)
    return reject(:REJECTED_SESSION, session) unless valid_op_code?(session.handshake[:op_code])
    return reject(:REJECTED_SESSION, session) unless valid_magic?(session.handshake[:magic])
    return reject(:INVALID_REVISION, session) unless valid_revision?(session.handshake[:protocol])
    return reject(:BAD_SESSION_ID, session) unless valid_seed?(session.cipher[:seed], session.handshake[:seed].raw_seed)
    return reject(:BAD_CREDENTIALS, session) unless first_time || valid_credentials?(session.handshake[:credentials], profile)
    return reject(:WORLD_OFFLINE, session) unless valid_availability?(target)
    return reject(:WORLD_IS_FULL, session) unless valid_capacity?(target)
    return reject(:CONFLICTING_SESSION, session) unless first_time || valid_profile?(profile, target)

    accept(session, profile, first_time)
  end

  # Accept a {RuneRb::Network::Session}
  # @param session [RuneRb::Network::Session] the session to accept.
  # @param profile [RuneRb::Database::PlayerProfile] the profile requested by the session.
  # @param first [Boolean] is this a first time login?
  def accept(session, profile, first)
    session.write_message(:RAW, data: [RuneRb::Network::LOGIN_RESPONSES[:SUCCESS], first ? 0 : profile.attributes.rights, 0].pack('ccc'))
    log COLORS.green("Accepted Session with signature #{session.sig}!")
    session.stage = :authenticated
    true
  end

  # Rejects a {RuneRb::Network::Session}.
  # @param reason [Symbol] the reason to reject the session.
  # @param session [RuneRb::Network::Session] the session to reject.
  def reject(reason, session)
    session.write_message(:RAW, data: [RuneRb::Network::LOGIN_RESPONSES[reason]].pack('C'))
    session.disconnect(:authentication)
    log! COLORS.red("Rejected Session with signature #{session.sig}!")
    false
  end

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
  def valid_revision?(protocol)
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

# Copyright (c) 2022, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
