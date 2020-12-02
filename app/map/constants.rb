# A collection of Map Constants
module RuneRb::Map::Constants
  NONE = -1
  NORTH_WEST = 0

  NORTH = 1
  NORTH_EAST = 2

  WEST = 3
  EAST = 4

  SOUTH_WEST = 5
  SOUTH = 6
  SOUTH_EAST = 7

  DIRECTIONS = { NONE: NONE,
                 NORTH_WEST: NORTH_WEST,
                 NORTH: NORTH,
                 NORTH_EAST: NORTH_EAST,
                 WEST: WEST,
                 EAST: EAST,
                 SOUTH_WEST: SOUTH_WEST,
                 SOUTH: SOUTH,
                 SOUTH_EAST: SOUTH_EAST }.freeze

  NESW = [NORTH, EAST, SOUTH, WEST].freeze
  WNES = [WEST, NORTH, EAST, SOUTH].freeze
  WNES_DIAGONAL = [NORTH_WEST, NORTH_EAST, SOUTH_EAST, SOUTH_WEST].freeze

  DEFAULT_POSITION = [ENV['DEFAULT_MOB_X'] || 3222, ENV['DEFAULT_MOB_Y'] || 3222, ENV['DEFAULT_MOB_Z'] || 0].freeze

  REGION_TILE_LENGTH = 8
  VIEWABLE_REGION_RADIUS = 3
  VIEWPORT_WIDTH = REGION_TILE_LENGTH * 13
  X_DELTAS = [-1, 0, 1, -1, 1, -1, 0, 1].freeze
  Y_DELTAS = [1, 1, 1, 0, 0, -1, -1, -1].freeze
end