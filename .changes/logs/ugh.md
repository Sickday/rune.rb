# Notes 1/28/2020

`Calyx::Item::ItemDefinition`

```ruby
class ItemDefinition
  extend T::Sig
   
  PROPERTIES = [:name, :noted, :parent, :noteable, :noteID, :stackable, :members, :prices, :basevalue, :att_stab_bonus,
                  :att_slash_bonus, :att_crush_bonus, :att_magic_bonus, :att_ranged_bonus, :def_stab_bonus, :def_slash_bonus,
                  :def_crush_bonus, :def_magic_bonus, :def_ranged_bonus, :strength_bonus, :prayer_bonus, :weight]
  BOOL_PROPERTIES = [:noted, :noteable, :stackable, :members, :prices]
    
  @db = nil
  DEFINITIONS = {}
    
  attr :id
  attr_reader :properties
    
  def initialize(id)
    @id = id
    @properties = lambda do |key|
      if PROPERTIES.include?(key)
        val = @db.get_first_value("select #{key} from items where id = #{@id}")
        BOOL_PROPERTIES.include?(key) ? val == 1 : val
      else
        nil
      end
    end
  end
    
  class ItemDefinition
    extend T::Sig
   
    PROPERTIES = [:name, :noted, :parent, :noteable, :noteID, :stackable, :members, :prices, :basevalue, :att_stab_bonus,
                  :att_slash_bonus, :att_crush_bonus, :att_magic_bonus, :att_ranged_bonus, :def_stab_bonus, :def_slash_bonus,
                  :def_crush_bonus, :def_magic_bonus, :def_ranged_bonus, :strength_bonus, :prayer_bonus, :weight]
    BOOL_PROPERTIES = [:noted, :noteable, :stackable, :members, :prices]
    
    @db = nil
    DEFINITIONS = {}
    
    attr :id
    attr_reader :properties
    
    def initialize(id)
      @id = id
      @properties = lambda do |key|
        if PROPERTIES.include?(key)
          val = @db.get_first_value("select #{key} from items where id = #{@id}")
          BOOL_PROPERTIES.include?(key) ? val == 1 : val
        else
          nil
        end
      end
    end
    
    PROPERTIES.each do |p|
      define_method(p.id2name) do
        @properties[p]
      end
    end
    
    def highalc
      (0.6 * basevalue).to_i
    end
    
    def lowalc
      (0.4 * basevalue).to_i
    end
    
    def ItemDefinition.for_id(id)
      if DEFINITIONS[id] == nil
        DEFINITIONS[id] = ItemDefinition.new(id)
      end
      
      DEFINITIONS[id]
    end
    
    def ItemDefinition.load
      @db = SQLite3::Database.new('./data/items.db', :readonly => true)
    end
  end
    
  def highalc
    (0.6 * basevalue).to_i
  end
  
  def lowalc
    (0.4 * basevalue).to_i
  end
    
  def ItemDefinition.for_id(id)
    if DEFINITIONS[id] == nil
      DEFINITIONS[id] = ItemDefinition.new(id)
    end
      
    DEFINITIONS[id]
  end
    
  def ItemDefinition.load
    @db = SQLite3::Database.new('./data/items.db', :readonly => true)
  end
end
```

Bruh.

```ruby
PROPERTIES = [:name, :noted, :parent, :noteable, :noteID, :stackable, :members, :prices, :basevalue, :att_stab_bonus,
                  :att_slash_bonus, :att_crush_bonus, :att_magic_bonus, :att_ranged_bonus, :def_stab_bonus, :def_slash_bonus,
                  :def_crush_bonus, :def_magic_bonus, :def_ranged_bonus, :strength_bonus, :prayer_bonus, :weight]
BOOL_PROPERTIES = [:noted, :noteable, :stackable, :members, :prices]
```



Ugh.

Why use a yoog Array for `PROPERTIES` and `BOOL_PROPERTIES`? Why not a `Struct` of some kind? In fact, why do we even NEED properties? Why not just return the data directly from the db? Why are we putting it all into a container like this?



![shitidontlike](assets/shitidontlike.gif)

`Sequel::Model` come check this fool

# needless shit

```ruby
PROPERTIES.each do |p|
  define_method(p.id2name) do
      @properties[p]
  end
end
```

This blocks just there chillin. No real place. Ran each time this file's loaded. SMH

```ruby
def ItemDefinition.for_id(id)
  if DEFINITIONS[id] == nil
    DEFINITIONS[id] = ItemDefinition.new(id)
  end
      
  DEFINITIONS[id]
end
    
def ItemDefinition.load
  @db = SQLite3::Database.new('./data/items.db', :readonly => true)
end
```

I can forgive talking about yourself in the 3rd person without using `self` , but like.

WHY ARE WE ALSO MAKING A NEW DATABASE OBJECT FOR EVER ITEMDEFINITION INSTANCE :weary:

Alright look 

if we're going to have it managing the db, make this variable able to be referenced outside of the scope of this object.

```ruby
class ItemDefinition < Sequel::Model(Point::To::Database[:ITEMS])
    unrestrict_primary_key
    def high_alch
        (0.6 * Sequel(:base_value)).to_i
    end
    def low_alch
       (0.4 * Sequel(:base_value)).to_i
    end
end
```

Really should be all we need to get the same behavior. Then we can call `item.definition[id][:stackable]` to get whether an item with `id` is stackable. ezpz