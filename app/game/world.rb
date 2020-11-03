module RuneRb::Game
  class World
    include RuneRb::Types::Loggable

    def initialize
      @entities = { players: [], mobs: [] }
    end

    def receive(entity)
      case entity
      when RuneRb::Entity::Context
        register_player(entity)
      when RuneRb::Entity::Mob
        register_mob(entity)
      else
        raise "Unrecognized entity registration! #{entity.inspect}"
      end
    end

    def release(entity)
      case entity.class
      when RuneRb::Entity::Context
        deregister_player(entity) unless valid_player?(entity)
      when RuneRb::Entity::Mob
        deregister_mob(entity) unless valid_mob?(entity)
      else
        raise "Unrecognized entity release! #{entity.inspect}"
      end
    end

    private

    def register_player(player)
      @entities[:players] << player
    end

    def register_mob(mob)
      @entities[:mobs] << mob
    end

    def deregister_player(player)
      @entities[:players].delete(player)
    end

    def deregister_mob(mob)
      @entities[:mobs].delete(mob)
    end

    def valid_player?(entity)
      false if !entity.session.status[:active] ||  !@entities[:players].include?(entity) || entity.status[:banned?]
    end

    def valid_mob?(entity)
      false if entity.status[:dead?] || !@entities[:mobs].include?(entity)
    end
  end
end