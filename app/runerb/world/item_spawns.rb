module RuneRb::World
  class ItemSpawns
    attr :items

    def self.load
      @items = []
      items = XmlSimple.xml_in('data/item_spawns.xml')
      items['item'].each_with_index { |row, _idx| @items << Item.new(row) }
      WORLD.submit_event(ItemEvent.new)
    end
  end

  class ItemEvent < RuneRb::Engine::Event
    def initialize
      super(1000)
    end

    def execute
      ItemSpawns.items.each do |item|
        item.respawn -= 1 if item.picked_up
        item.spawn if item.picked_up && item.respawn <= 0
      end
    end
  end

  class Item
    attr :item
    attr :location
    attr_accessor :respawn
    attr :orig_respawn
    attr :picked_up
    attr :on_table

    def initialize(data)
      @item = RuneRb::Item::Item.new(data['id'].to_i, data.include?('amount') ? data['amount'].to_i : 1)
      @location = RuneRb::Model::Location.new(data['x'].to_i, data['y'].to_i, data['z'].to_i)
      @respawn = data.include?('respawn') ? data['respawn'].to_i : 300 # Number of seconds before it will respawn
      @orig_respawn = @respawn
      @picked_up = false
      @on_table = data.include?('ontable') && data['ontable'] == 'true'
    end

    def remove
      @picked_up = true

      WORLD.region_manager.get_local_players(@location).each do |player|
        player.io.send_grounditem_removal(self)
      end
    end

    def spawn(player = nil)
      @picked_up = false
      @respawn = @orig_respawn

      unless player.nil?
        player.io.send_grounditem_creation(self)
        return
      end

      WORLD.region_manager.get_local_players(@location).each do |p|
        p.io.send_grounditem_creation(self)
      end
    end

    def within_distance?(player)
      player.location.within_distance? @location
    end

    ##
    # TODO: Impl
    def available
      true
    end
  end
end
