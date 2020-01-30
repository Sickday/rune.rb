# typed: true
module RSRS
  class World < API::AssetManager
    extend T::Sig

    sig{returns(RSRS::World)}
    ##
    # Create a new World instance.
    def initialize
      load_db_manager
      load_items
      load_npcs
      self
    end

    private

    sig{returns(RSRS::DatabaseManager)}
    ##
    # Creates our World's DatabaseManager.
    # TODO: Delegate this functionality (asset loading) to the Server object so that multiple Worlds can utilize the same Database.
    def load_db_manager
      begin
        ASSETS[:DatabaseManager] = DatabaseManager.new
      rescue SQLite3::SQLException => e
        p e
      end
    end

    sig{returns(Class)}
    ##
    # Creates a Model for each Item.
    # TODO: Delegate this functionality (asset loading) to the Server object so that multiple Worlds can utilize the same Database.
    def load_items
      begin
        ASSETS[:Items] = RSRS::Models::Item.set_dataset(ASSETS[:DatabaseManager][:AssetDatabase][:items])
      rescue SQLite3::SQLException => e
        p e
      end
    end

    sig{returns(Class)}
    ##
    # Creates a Model for each NPC
    # TODO: Delegate this functionality (asset loading) to the Server object so that multiple Worlds can utilize the same Database.
    def load_npcs
      begin
        ASSETS[:NPCs] = RSRS::Models::NPC.set_dataset(ASSETS[:DatabaseManager][:AssetDatabase][:npcs])
      rescue SQLite3::SQLException => e
        p e
      end
    end
  end
end