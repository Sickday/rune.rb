module RuneRb::Game
  class World
    include RuneRb::Types::Loggable

    attr :entities, :services

    def initialize
      @entities = { players: [], mobs: [] }
    end

    # Receives and registers an entity to the world.
    def receive(entity)
      @services[:sync].execute do
        case entity
        when RuneRb::Entity::Context
          @entities[:players] << entity
        when RuneRb::Entity::Mob
          @entities[:mobs] << entity
        else
          raise "Unrecognized entity registration! #{entity.inspect}"
        end
      end
    end

    # Releases and unregisters entity from the World
    # @param entity [RuneRb::Entity::Type] the entity to release.
    def release(entity)
      @services[:sync].execute do
        case entity
        when RuneRb::Entity::Context
          @entities[:players].delete(entity)
        when RuneRb::Entity::Mob
          @entities[:mobs].delete(entity)
        else
          raise "Unrecognized entity release! #{entity.inspect}"
        end
      end
    end
  end
end