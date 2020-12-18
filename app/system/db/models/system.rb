module RuneRb::System::Database
  class BannedNames < Sequel::Model(RuneRb::BANNED_NAMES); end
  class Snapshots < Sequel::Model(RuneRb::SNAPSHOTS); end
end