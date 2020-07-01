module RuneRb::World
  RIGHTS = %i[player mod admin owner].freeze

  PROFILE_LOG = Logging.logger['profile']
  PLUGIN_LOG = Logging.logger['plugin']

  MAXIMUM_WAYPOINT_SIZE = 50
  DIRECTION_DELTA_X = [-1, 0, 1, -1, 1, -1, 0, 1].freeze
  DIRECTION_DELTA_Y = [1, 1, 1, 0, 0, -1, -1, -1].freeze
  DIRECTIONS = [[5, 3, 0], [6, -1, 1], [7, 4, 2]].freeze

  NPC_DIRECTIONS = {north: [0, 1], south: [0, -1],
                    east: [1, 0], west: [-1, 0],
                    northeast: [1, 1], northwest: [-1, 1],
                    southeast: [1, -1], southwest: [-1, -1]}.freeze

  class Constants; end
end