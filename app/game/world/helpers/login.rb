module RuneRb::World::LoginHelper

  # @return [Hash] a map of response codes and symbol keys indicative of their meaning.
  RESPONSES = { RETRY_COUNT: -1, OK: 0, RETRY: 1, SUCCESS: 2,
                BAD_CREDENTIALS: 3, BANNED_ACCOUNT: 4, CONFLICTING_SESSION: 5,
                INVALID_REVISION: 6, WORLD_IS_FULL: 7, LOGIN_OFFLINE: 8,
                TOO_MANY_CONNECTIONS: 9, BAD_SESSION_ID: 10, REJECTED_SESSION: 11,
                NON_MEMBERS: 12, WORLD_OFFLINE: 13, UPDATE_IN_PROGRESS: 14,
                TOO_MANY_ATTEMPTS: 16, BAD_POSITION: 17, BAD_LOGIN_SERVER: 20,
                WORLD_TRANSFER: 21 }.freeze

  # Receives a peer object and attempts to register the peer to the World Instance.
  def login(peer, login_block, connection_block)
    return unless validate_type(peer, login_block)
    return unless validate_seed(peer, login_block, connection_block)
    return unless validate_magic(peer, login_block)
    return unless validate_revision(peer, login_block)
    return unless validate_credentials(peer, login_block)

    receive(peer, fetch_profile(login_block))
  end

  private

  def fetch_profile(block)
    RuneRb::Database::Profile[block[:Username]] || RuneRb::Database::Profile.register(block)
  end

  # Attempts to validate the credentials of the login block
  def validate_credentials(peer, block)
    log "Validating Credentials for #{peer.ip}"if RuneRb::DEBUG
    unless block[:Username].length >= 1 && RuneRb::Database::SYSTEMS[:banned_names].all.none? { |row| row[:names].include?(block[:Username]) }
      log RuneRb::COL.red("Invalid Username for #{RuneRb::COL.yellow(block[:Username])}")
      peer.send_data([RESPONSES[:BAD_CREDENTIALS]].pack('C'))
      peer.close_connection(true)
      return false
    end

    profile = fetch_profile(block)
    log RuneRb::COL.green("Loaded profile data for #{RuneRb::COL.yellow(profile[:name].capitalize)}")

    unless profile[:password] == block[:Password]
      log RuneRb::COL.red("Invalid Password for #{RuneRb::COL.yellow(profile[:name])}!")
      peer.send_data([RESPONSES[:BAD_CREDENTIALS]].pack('C'))
      peer.close_connection(true)
      return false
    end
    log RuneRb::COL.green('Credentials validated!') if RuneRb::DEBUG

    unless profile[:banned] == false
      log RuneRb::COL.red.bold("Profile is banned from this network!") if RuneRb::DEBUG
      peer.send_data([RESPONSES[:BANNED_ACCOUNT]].pack('C'))
      peer.close_connection(true)
    end
    log RuneRb::COL.green('Status validated!') if RuneRb::DEBUG

    # We can send a successful response to the peer.
    peer.write(:response, response: RESPONSES[:SUCCESS], rights: profile.rights, flagged: 0)
    peer.write(:login)
    true
  end

  # Attempts to validate the connection type
  def validate_type(peer, block)
    log "Validating Login type for #{peer.ip}" if RuneRb::DEBUG
    unless [16, 18].include?(block[:Type])
      err 'Unrecognized Connection type! Rejecting Session.', "Received: #{block[:Type]}"
      peer.send_data([RESPONSES[:REJECTED_SESSION]].pack('C'))
      peer.close_connection(true)
      return false
    end
    log RuneRb::COL.green('Validated!') if RuneRb::DEBUG
    true
  end

  # Attempts to validate the seed received in the login block.
  def validate_seed(peer, login_block, connection_block)
    log "Validating Seed pair for #{peer.ip}" if RuneRb::DEBUG
    unless login_block[:LoginSeed] == connection_block[:ConnectionSeed]
      err 'Seed Mismatch!:', "Expected: #{connection_block[:ConnectionSeed]}, Received: #{login_block[:LoginSeed]}"
      peer.send_data([RESPONSES[:BAD_SESSION_ID]].pack('C'))
      peer.close_connection(true)
      return false
    end
    log RuneRb::COL.green('Seed Validated!') if RuneRb::DEBUG
    true
  end

  # Attempts to validate the magic in the login block.
  def validate_magic(peer, block)
    log "Validating Magic for #{peer.ip}" if RuneRb::DEBUG
    unless block[:Magic] == 0xff
      err 'Unexpected Magic!', "Expected: 255, Received: #{block[:Magic]}"
      peer.send_data([RESPONSES[:REJECTED_SESSION]].pack('C'))
      peer.close_connection(true)
      return false
    end
    log RuneRb::COL.green('Magic Validated!') if RuneRb::DEBUG
    true
  end

  # Attempts to validate the revision in the login block.
  def validate_revision(peer, block)
    log "Validating Revision for #{peer.ip}" if RuneRb::DEBUG
    unless [317, 377, ENV['TARGET_PROTOCOL']].include?(block[:Revision])
      err 'Unexpected Protocol', "Expected: #{[317, 377, ENV['TARGET_PROTOCOL']]}, Received: #{block[:Revision]}"
      peer.send_data([RESPONSES[:INVALID_REVISION]].pack('C'))
      peer.close_connection(true)
      return false
    end
    log RuneRb::COL.green('Revision Validated!') if RuneRb::DEBUG
    true
  end
end