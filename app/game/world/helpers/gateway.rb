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

module RuneRb::Game::World::Gateway

  # Receives a session and attempts to authorize the login attempt. If the session is valid, a Context entity is created and added to the <@entities> collection. If the session is invalid, an appropriate response is dispatched to the session before the connection is closed by the session.
  # @param session [RuneRb::Network::Session] the session that is attempting to login
  def receive(session)
    post(id: :RECEIVE_SESSION, priority: :HIGH, assets: [session, @entities[:players], self]) do |sess, players, world|
      if authorized?(sess) && players.values.none? { |player| player.session == sess }
        ctx = RuneRb::Game::Entity::Context.new(sess, RuneRb::Database::PlayerProfile.fetch_profile(sess.login[:Credentials]), world)
        ctx.index = players.empty? ? 1 : players.keys.last + 1
        players[ctx.index] = ctx
        ctx.login
        log RuneRb::GLOBAL[:COLOR].green("Registered new Context for #{RuneRb::GLOBAL[:COLOR].yellow(ctx.profile[:name].capitalize)}") if RuneRb::GLOBAL[:DEBUG]
        log RuneRb::GLOBAL[:COLOR].green("Welcome, #{RuneRb::GLOBAL[:COLOR].yellow.bold(ctx.profile[:name].capitalize)}!")
      end
    end
  end

  # Removes a context mob from the Instance#entities hash, then calls Context#logout on the specified mob to ensure a logout is performed.
  # @param context [RuneRb::Game::Entity::Context] the context mob to release
  def release(context)
    post(id: :RELEASE_CONTEXT, priority: :HIGH, assets: [@entities[:players], context]) do |players, ctx|
      # Remove the context from the entity list
      players.delete_if { |_idx, entity| ctx.session.id == entity.session.id }

      # Logout the context.
      ctx.logout if ctx.session.status[:auth] == :LOGGED_IN
      log RuneRb::GLOBAL[:COLOR].green.bold("Released Context for #{RuneRb::GLOBAL[:COLOR].yellow(context.profile[:name].capitalize)}") if RuneRb::GLOBAL[:DEBUG]
      log RuneRb::GLOBAL[:COLOR].magenta("See ya, #{RuneRb::GLOBAL[:COLOR].yellow(context.profile[:name].capitalize)}!")
    end
  end

  private

  def authorized?(session)
    @responses[session] ||= RuneRb::Network::Message.new('w', { op_code: -1 }, :RAW)

    false unless valid_operation_code?(session)
    false unless valid_seed?(session)
    false unless valid_magic?(session)
    false unless valid_revision?(session)
    false unless valid_credentials?(session)
    false unless valid_status?(session)

    log! "Authorized #{session.login[:Credentials][:Username].capitalize}!"

    @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:SUCCESS], type: :byte, signed: false)
    @responses[session].write(RuneRb::Database::PlayerProfile.fetch_profile(session.login[:Credentials])[:rights], type: :byte, signed: false)
    @responses[session].write(0, type: :byte, signed: false)
    session.write_message(:raw, message: @responses[session])
    @responses.delete(session)

    true
  rescue RuneRb::System::Errors::SessionReceptionError => e
    err e.message
    session.write_message(:raw, message: @responses[session])
    session.disconnect(:authentication)
    @responses.delete(session)

    false
  end

  # Attempts to validate the connection type
  # @api private
  def valid_operation_code?(session)
    if [RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE],
        RuneRb::Network::CONNECTION_TYPES[:GAME_RECONNECT]].include?(session.login[:OperationCode])
      true
    else
      @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION], type: :byte, signed: false)
      raise RuneRb::System::Errors::SessionReceptionError.new(:op_code, [RuneRb::Network::CONNECTION_TYPES[:GAME_ONLINE], RuneRb::Network::CONNECTION_TYPES[:GAME_RECONNECT]],
                                                              session.login[:OperationCode])
    end
  end

  # Attempts to validate the seed received in the login block.
  # @api private
  def valid_seed?(session)
    if session.login[:LoginSeed] == session.login[:ConnectionSeed]
      true
    else
      @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:BAD_SESSION_ID], type: :byte, signed: false)
      raise RuneRb::System::Errors::SessionReceptionError.new(:seed, session.login[:LoginSeed], session.login[:ConnectionSeed])
    end
  end

  # Attempts to validate the magic in the login block.
  # @api private
  def valid_magic?(session)
    if session.login[:Magic] == 0xff
      true
    else
      @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:REJECTED_SESSION], type: :byte, signed: false)
      raise RuneRb::System::Errors::SessionReceptionError.new(:magic, session.login[:Magic], 0xff)
    end
    true
  end

  # Attempts to validate the revision in the login block.
  # @api private
  def valid_revision?(session)
    if RuneRb::GLOBAL[:PROTOCOL].to_s.gsub('RS', '').to_i == session.login[:Revision]
      true
    else
      @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:INVALID_REVISION], type: :byte, signed: false)
      raise RuneRb::System::Errors::SessionReceptionError.new(:revision, RuneRb::GLOBAL[:PROTOCOL].to_s.gsub('RS', '').to_i, session.login[:Revision])
    end
  end

  # Attempts to validate the credentials of the login block
  # @api private
  def valid_credentials?(session)
    if session.login[:Credentials][:Username].length >= 1 && RuneRb::GLOBAL[:GAME_BANNED_NAMES].none? { |row| row[:name].include?(session.login[:Credentials][:Username]) }
      true
    else
      @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:BAD_CREDENTIALS], type: :byte, signed: false)
      raise RuneRb::System::Errors::SessionReceptionError.new(:username, nil, session.login[:Credentials][:Username])
    end

    if RuneRb::Database::PlayerProfile.fetch_profile(session.login[:Credentials])[:password] == session.login[:Credentials][:Password]
      true
    else
      @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:BAD_CREDENTIALS], type: :byte, signed: false)
      raise RuneRb::System::Errors::SessionReceptionError.new(:password, nil, nil)
    end
    true
  end

  def valid_status?(session)
    if RuneRb::Database::PlayerProfile.fetch_profile(session.login[:Credentials])[:banned] == false
      true
    else
      @responses[session].write(RuneRb::Network::LOGIN_RESPONSES[:BANNED_ACCOUNT], type: :byte, signed: false)
      raise RuneRb::System::Errors::SessionReceptionError.new(:banned, nil, session.login[:Credentials][:Username])
    end
    true
  end
end