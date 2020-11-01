module RuneRb::Game
  class World
    include RuneRb::Types::Serializable

    def initialize
      self[:entities] = { players: [], mobs: [] }
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
=begin

    # Loads a serialized string and returns a new instance of self
    def self.restore(serialized_string)
      parsed_world = Oj.safe_load(serialized_string)
      parse_entities(parsed_world)
    end
=end

    private

    def register_player(player)
      self[:entities][:players] << player
    end

    def register_mob(mob)
      self[:entities][:mobs] << mob
    end

    def deregister_player(player)
      self[:entities][:players].delete(player)
    end

    def deregister_mob(mob)
      self[:entities][:mobs].delete(mob)
    end

    def launch_services
      self[:services] = {
        map: RuneRb::Services::MapService.new(self),
        update: RuneRb::Services::UpdateService.new(self)
      }
    end

=begin
    def dump_entities
      base = super
      self[:entities].each do |type, collection|

      end
    end

    def parse_entities(string)
      self[:entities] = { players: [], mobs: [] }
      string[':entities'][':players'].each do |unparsed_player|
        self[:entities][:players] << RuneRb::Entity::Context.restore(unparsed_player)
      end
    end
=end

    def valid_player?(entity)
      false if entity.session.idle? || entity[:data].banned || !self[:entities][:players].include?(entity)
    end

    def valid_mob?(entity)
      false if entity.status[:dead?] || !self[:entities][:mobs].include?(entity)
    end
  end
end