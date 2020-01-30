# typed: true
module RSRS
  class DatabaseManager < API::AssetManager
    extend T::Sig

    sig{returns(RSRS::DatabaseManager)}
    ##
    # Creates a new DatabaseManager
    def initialize
      _tmp = Sequel.sqlite
      Dir[File.dirname(__FILE__) + '/scripts/*.sql'].each do |sql|
        begin
          _tmp.run(IO.binread(sql))
        rescue SQLite3::SQLException => e
          puts e
        end
      end
      ASSETS[:AssetDatabase] = _tmp
      self
    end
  end
end