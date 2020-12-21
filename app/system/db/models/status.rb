module RuneRb::System::Database
  class Status < Sequel::Model(RuneRb::PLAYER_STATUS)

    # Update the status with a ban.
    def ban(session)
      update(banned: true)
      post_session(session)
      session.write(:logout)
    end

    # Update the status with a mute.
    def mute(session)
      update(muted: true)
      post_session(session)
      session.write(logout)
    end

    def promote(to)

    end

    # Updates the last session column with information from the passed session object.
    def post_session(session)
      info = {}
      info[:ip] = session.ip
      info[:duration] = session.up_time
      info[:date] = session.start[:stamp]
      update(last_session: Oj.dump(info))
    end
  end
end