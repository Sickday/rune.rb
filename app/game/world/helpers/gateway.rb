module RuneRb::Game::World::Gateway
  include RuneRb::Utils::Logging

  # Receives a session and attempts to authorize the login attempt. If the session is valid, a Context entity is created and added to the <@entities> collection. If the session is invalid, an appropriate response is dispatched to the session before the connection is closed by the session.
  # @param session [RuneRb::Network::Session] the session that is attempting to login
  def receive(session)
    post(id: :RECEIVE_SESSION, priority: :HIGH, assets: [session, @entities[:players], self]) do |sess, players, world|
      profile = RuneRb::Database::Player::Profile.fetch_profile(sess.auth[:credentials_block].username)
      status = authenticated?(sess.auth[:seed], profile, sess.auth[:credentials_block], sess.auth[:login_block])
      if status.is_a?(Integer)
        reject(sess, status)
      else
        profile ||= RuneRb::Database::Player::Profile.register(sess.auth[:credentials_block])
        accept(sess, profile)
        ctx = RuneRb::Game::Entity::Context.new(sess, profile, world)
        ctx.index = players.empty? ? 1 : players.keys.last + 1
        players[ctx.index] = ctx
        ctx.login
        log COLORS.green("Registered new Context for #{COLORS.yellow(ctx.profile[:username].capitalize)}") if RuneRb::GLOBAL[:ENV].debug
        log COLORS.green("Welcome, #{COLORS.yellow.bold(ctx.profile[:username].capitalize)}!")
      end
    end
  end

  # Removes a context mob from the Instance#entities hash, then calls Context#logout on the specified mob to ensure a logout is performed.
  # @param context [RuneRb::Game::Entity::Context] the context mob to release
  def release(context)
    post(id: :RELEASE_CONTEXT, priority: :HIGH, assets: [@entities[:players], context]) do |players, ctx|
      # Logout the context.
      ctx.logout if ctx.session.auth[:stage] == :logged_in
      # Remove the context from the entity list
      players.delete(ctx)
      log COLORS.green.bold("Released Context for #{COLORS.yellow(context.profile[:username].capitalize)}") if RuneRb::GLOBAL[:ENV].debug
      log COLORS.magenta("See ya, #{COLORS.yellow(context.profile[:username].capitalize)}!")
    end
  end

  private

  def authenticated?(seed, profile, credential_block, login_block)
    log "Authenticating session for user #{credential_block.username}"
    return RuneRb::Network::LOGIN_RESPONSES[:BANNED_ACCOUNT] unless profile.nil? || valid_banned_status?(profile)
    return RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION] unless valid_op_code?(login_block)
    return RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION] unless valid_magic?(login_block)
    return RuneRb::Network::LOGIN_RESPONSES[:INVALID_REVISION] unless valid_revision?(login_block)
    return RuneRb::Network::LOGIN_RESPONSES[:BAD_SESSION_ID] unless valid_seed?(credential_block, seed)
    return RuneRb::Network::LOGIN_RESPONSES[:BAD_CREDENTIALS] unless profile.nil? || valid_credentials?(credential_block, profile)

    true
  end

  # Rejects a {RuneRb::Network::Session}.
  # @param code [Integer] the Response code which correlates with the reason for rejection. See {Gateway#RESPONSES}
  def reject(session, code)
    log! COLORS.red("Rejecting Session with signature #{session.sig}")
    session.write_message(:RAW, data: [code].pack('C'))
  end

  # Accept a {RuneRb::Network::Session}
  def accept(session, profile)
    log! COLORS.green("Accepted Session with signature #{session.sig}")
    session.write_message(:RAW, data: [RuneRb::Network::LOGIN_RESPONSES[:SUCCESS], profile[:rights], 0].pack('ccc'))
  end

  # Checks if a session's login block op_code is valid.
  # @param login_block [Struct] the session's login_block
  # @return [Boolean] is the op_code valid?
  # @api private
  def valid_op_code?(login_block)
    unless [RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE],
            RuneRb::Network::CONNECTION_TYPES[:GAME_RECONNECT]].include?(login_block.op_code)
      err "Unrecognized Connection type! [Expected: [16, 18], Received: #{login_block.op_code}]"
      return false
    end
    true
  end

  # Checks if a session's seed is the same as the client's seed.
  # @param credential_block [Struct] the session's credential_block
  # @param seed [Integer] the session's seed
  # @return [Boolean] is the seed valid?
  # @api private
  def valid_seed?(credential_block, seed)
    unless seed == credential_block.client_seed
      err "Seed Mismatch! [Expected: #{credential_block.seed}, Received: #{credential_block.client_seed}]"
      return false
    end
    true
  end

  # Checks if a session's magic is the same as the client's magic.
  # @param login_block [Struct] the session's login_block
  # @return [Boolean] is the magic valid?
  # @api private
  def valid_magic?(login_block)
    unless login_block.magic == 0xff
      err "Unexpected Magic! [Expected: 255, Received: #{login_block.magic}]"
      return false
    end
    true
  end

  # Checks if a session's revision is supported by the application.
  # @param login_block [Struct] the login_block for the session.
  # @api private
  def valid_revision?(login_block)
    unless RuneRb::GLOBAL[:ENV].server_config.protocol == login_block.revision
      err "Unsupported Protocol! [Expected: #{RuneRb::GLOBAL[:ENV].server_config.protocol}, Received: RS#{login_block.revision}]"
      return false
    end
    true
  end

  # Checks the credentials of the credentials_block for a session
  # @param credential_block [Struct] the credential_block of the session
  # @param profile [RuneRb::Database::Player::Profile] the profile fetched by username
  # @return [Boolean] are the credentials valid?
  # @api private
  def valid_credentials?(credential_block, profile)
    unless credential_block.username.length >= 1 && !RuneRb::Database::System::BannedNames.check(credential_block.username)
      log COLORS.red("Invalid Username for #{COLORS.yellow(credential_block.username)}")
      return false
    end

    unless profile[:password] == credential_block.password
      log COLORS.red("Invalid Password for #{COLORS.yellow(profile[:username].capitalize)}!")
      return false
    end

    true
  end

  # Validate the banned status of the profile
  # @param profile [RuneRb::Database::Player::Profile]
  def valid_banned_status?(profile)
    unless profile[:banned] == false
      log COLORS.red.bold("#{profile[:username]} is banned from this network!")
      return false
    end
    true
  end
end

# Copyright (c) 2021, Patrick W.
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