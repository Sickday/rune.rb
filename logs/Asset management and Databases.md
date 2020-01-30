# Asset management

I needed a way to elegantly manage assets, so I made the AssetManager:

```ruby
module RSRS
  class AssetManager

    ASSETS = {}

    ##
    # Shorthand for asset retrieval.
    def [](key)
      ASSETS[key]
    end

    private

    ##
    # Loads resources into this Manager.
    def load_resources; end
  end
end
```

Nothing complex going on, we just have our `ASSETS` hash, and a `AssetManager#[]` shorthand to allow us to retrieve assets like so:

```ruby
AssetManager[:key] # => AssetManager::ASSETS[:key]
```



The `RSRS::World` object inherits this functionality as it is technically a child class of `RSRS::AssetManager`. I did this to allow us to reference components of the game world easily. Here's the full implementation of the `RSRS::World`

```ruby
# typed: true
module RSRS
  class World < AssetManager
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
```

Ignoring the `sorbet` stuff, you can see there isn't much to the World right now. That's perfect as the rest will fill in as we add more functionality :thumbsup: . For the meantime, lets focus on how we can utilize the `AssetManager` functionality in the World.

There are 3 points where we populate the `AssetManager::ASSETS` object. 

```ruby
ASSETS[:DatabaseManager] = DatabaseManager.new
ASSETS[:Items] = RSRS::Models::Item.set_dataset(ASSETS[:DatabaseManager][:AssetDatabase][:items])
ASSETS[:NPCs] = RSRS::Models::NPC.set_dataset(ASSETS[:DatabaseManager][:AssetDatabase][:npcs])
```

* `ASSETS[:DatabaseManager]` - This creates a new `RSRS::DatabaseManager` object and assigns it to the `ASSETS[:DatabasManager]` hash with the appropriate key. This allows us to call the DatabaseManager whenever we need to by supplying it as a key to the World instance. (eg `TestWorld[:DatabaseManager]`)
* `ASSETS[:Items]` - This creates a `RSRS::Models::Item` Object and sets it's primary dataset to `ASSETS[:DatabaseManager][:AssetDatabase]`. The latter references our AssetDatabase contianing the `items` table with all of our items. `Sequel::Model` handles the actual SQL backend, allowing us call methods on the `RSRS::Models::Item`  model directly without having to use SQL at all. Though this is still possible, it's not necessary. Since we're associating the `:Items` key with it, we can reference items by supplying the key to the world as well as the item ID (we have Item ID's acting as their Primary Keys/Unique Constraints). Example: `TestWorld[:Items][4151]` would return a hash containing all data related to the Abyssal Whip (item 4151)
* `ASSETS[:NPCs]` - Same as above, except this deals solely with NPC data. Example: `TestWorld[:NPCs][50]` would return a hash containing data related to King Black Dragon (npc 50)



# Databases

I wanted a more reliable way to access data than raw text files, so I made a small DatabaseManager.

```ruby
# typed: true
module RSRS
  class DatabaseManager < AssetManager
    extend T::Sig

    sig{returns(RSRS::DatabaseManager)}
    ##
    # Creates a new DatabaseManager
    def initialize
      _tmp = Sequel.sqlite
      Dir[File.dirname(__FILE__) + '/../../../data/scripts/*.sql'].each do |sql|
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
```



Now I ran into an issue trying to run the sql files and ensure the database was in-memory, but I resolved that by making a single in-memory database and running the sql files against it to create [and populate] the respective tables. As this is a `Sequel::Dataset` we can talk to the instance directly to query for data. Eg.

```ruby
DB = RSRS::DatabaseManager.new
DB[:AssetDatabase][:items][4151].inspect # => "#<RSRS::Models::Item @values={:id=>4151, :name=>\"Abyssal whip\", :noted=>false, :parent=>-1, :noteable=>true, :noteID=>4152, :stackable=>false, :members=>true, :prices=>true, :basevalue=>100001, :att_stab_bonus=>0, :att_slash_bonus=>82, :att_crush_bonus=>0, :att_magic_bonus=>0, :att_ranged_bonus=>0, :def_stab_bonus=>0, :def_slash_bonus=>0, :def_crush_bonus=>0, :def_magic_bonus=>0, :def_ranged_bonus=>0, :strength_bonus=>82, :prayer_bonus=>0, :weight=>\"0.45\"}>"

```

