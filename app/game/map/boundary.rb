module RuneRb::Game::Map
  ##
  # Author: Patrick W.
  # Date: 9.14.2020
  class Boundary < Struct.new(:low_x, :high_x, :low_y, :high_y, :z)
    # An internal entity list for the Boundary.
    ENTITIES = { players: [], mobs: [] }.freeze

    # Called when a new Boundary is created.
    def initialize(*args)
      super
      @low_x = self.low_x
      @high_x = self.high_x
      @low_y = self.low_y
      @high_y = self.high_y
      @height = self.z
    end

    # returns the center position of the boundary
    # @return [Tile] the center position of the boundary
    def center
      x = (@low_x + @high_x) / 2
      y = (@low_y + @high_y) / 2
      @height > 0 ? Test::Game::Map::Tile.new(x, y, @height) : Test::Game::Map::Tile.new(x, y, 0)
    end

    # returns a collection of players within the boundary. Player's current tile is verified during the process.
    # @return [Array] a collection of players within the boundary
    def players
      ENTITIES[:players].map { |plyr| verify_tile(plyr.location.tile) }
    end

    # returns a collection of mobs within the boundary. Mob's current tile is verified during the process
    # @return [Array] a collection of mobs within the boundary.
    def mobs
      ENTITIES[:mobs].map { |mob| verify_tile(mob) }
    end


    # attempts to register an entity to the boundary
    # @param entity [Test::Game::Entity] the entity to register
    def register(entity)
      if verify_tile(entity.tile)
        case entity.class
        when Test::Game::Player
          ENTITIES[:players].include?(entity) ? raise "Player already registered to boundary!" : ENTITIES[:players] << entity
        when Test::Game::Mob
          ENTITIES[:mob] << entity
        else
          raise "Unrecognized entity not registered to boundary!"
        end
      else
        raise "Invalid entity registration for boundary:\t #{self.inspect}! Entity not within bounds!"
      end
    end

    # attempts to deregister an entity from the boundary
    # @param entity [Test::Game::Entity] the entity to deregister
    def deregister(entity)
      if verify_tile(entity.tile)
        case entity.class
        when Test::Game::Player
          ENTITIES[:players].include?(entity) ? raise "Player already registered to boundary!" : ENTITIES[:players].delete(entity)
        when Test::Game::Mob
          ENTITIES[:mob]&.delete(entity)
        else
          raise "Unrecognized entity cant be removed from boundary!"
        end
      else
        raise "Invalid entity deregistration for boundary:\t #{self.inspect}! Entity not found within bounds!"
      end
    end

    private

    # Ensures a tile is [actually] within the boundary's... bounds.
    # @param tile [Tile] the tile to verify
    def verify_tile(tile)
      return false if tile.z > @height # height level
      return false unless (tile.x >= @low_x && tile.x <= @high_x) # x position
      return false unless (tile.y >= @low_y && tile.y <= @high_y) # y position
      true
    end
  end
end