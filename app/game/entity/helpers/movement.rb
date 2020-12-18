module RuneRb::Game::Entity::Helpers::Movement
  # @return [Hash] a hash containing the movement type and waypoints.
  attr :movement

  # @return [Hash] a map of local mobs and players
  attr :locals

  # @return [Hash] the current previous positions of the mob in the virtual game map.
  attr :position

  # Initializes and sets the movement and locals objects.
  def load_movement
    @movement = { type: :NONE,
                  directions: { primary: RuneRb::Game::Map::DIRECTIONS[:NONE],
                                secondary: RuneRb::Game::Map::DIRECTIONS[:NONE],
                                previous: RuneRb::Game::Map::DIRECTIONS[:NORTH] },
                  waypoints: { next: [],
                               previous: [] } }
    @locals = { mobs: [], players: [] }
  end

  # Toggles the running mode for the queue.
  def toggle_run
    @movement[:running] = true
  end

  # Clears the queue
  def clear_waypoints
    @movement[:waypoints][:next]&.clear
    @movement[:waypoints][:previous]&.clear
    reset_movement
  end

  # Teleports the Mob to a new position.
  # @param to [RuneRb::Game::Map::Position] the position to teleport to.
  def teleport(to)
    clear_waypoints
    update(:teleport, to: to)
  end

  # Pushes a path to the queue
  # @param path [Array] an array of positions that make up the path
  def push_path(path)
    log "Adding path: #{RuneRb::COL.yellow(path.inspect)}"
    push_primary_step(path.shift) if @movement[:waypoints][:next].size.zero?
    path.each do |position|
      push_step(position)
    end
  end

  # Attempts to parse movement from a frame
  # @param frame [RuneRb::Network::Frame] the frame to read from.
  def parse_movement(frame)
    log "Received movement packet: #{frame.header[:op_code]}" if RuneRb::GLOBAL[:RRB_DEBUG]
    length = frame.header[:length]
    length -= 14 if frame.header[:op_code] == 248

    steps = (length - 5) / 2
    return unless steps.positive?

    path = []
    first_x = frame.read_short(false, :A, :LITTLE)
    steps.times do |itr|
      path[itr] ||= [frame.read_byte(true),
                     frame.read_byte(true)]
    end

    first_y = frame.read_short(false, :STD, :LITTLE)
    @movement[:running] = frame.read_byte(false, :C) == 1

    positions = []
    positions << RuneRb::Game::Map::Position.new(first_x, first_y)
    steps.times do |itr|
      positions << RuneRb::Game::Map::Position.new(path[itr][0] + first_x,
                                             path[itr][1] + first_y)
    end

    push_path(positions.flatten.compact) unless positions.empty?
  end

  # The number of waypoints left in the movement path
  # @return [Integer] the number of steps left.
  def waypoint_size
    @movement[:waypoints][:next].size
  end

  # Resets the movement
  def reset_movement
    if (@movement[:waypoints][:next].empty? || @movement[:type] == :TELEPORT) && @movement[:type] != :NONE
      @movement[:type] = :NONE
    end
    @movement[:running] = false
  end

  private

  # Pulse through the queue
  def move
    directions = [RuneRb::Game::Map::DIRECTIONS[:NONE],
                  RuneRb::Game::Map::DIRECTIONS[:NONE]]

    # world = @player.world
    # collision = @player.world[:collision_manager]

    next_point = @movement[:waypoints][:next].shift
    log "Got point #{next_point.inspect}" unless next_point.nil?

    unless next_point.nil?
      directions[0] = RuneRb::Game::Map::Direction.between(@position[:current], next_point)
      log "Worked out 1st direction to be #{RuneRb::Game::Map::DIRECTIONS.key(directions.first)}"

      # Handle collision here
      # Add this point to the previous waypoints
      @movement[:waypoints][:previous] << next_point
      # Set the direction
      @movement[:directions][:primary] = directions[0]
      # Ensure the previous position is re-assigned if there was no initial movement (indicating we're starting a path)
      @position[:previous] = @position[:current] if @movement[:type] == :NONE
      #@position[:current].move(RuneRb::Game::Map::X_DELTAS[directions[0]], RuneRb::Game::Map::Y_DELTAS[directions[0]])
      @position[:current] = next_point
      @movement[:type] = :WALK

      log "Updated Pos to #{@position[:current].inspect}"
    end
  end

  # Push the very first step into the queue
  # @param next_position [RuneRb::Game::Map::Position] the next position.
  def push_primary_step(next_position)
    log RuneRb::COL.green("Adding primary position #{next_position.inspect}")
    # First we clear all previous waypoints as this is the first step in the path
    @movement[:waypoints][:previous].clear
    push_step(next_position)
  end

  # Push a step into the queue
  def push_step(position)
    # Get the next position
    current = @movement[:waypoints][:next].last
    current ||= @position[:current]
    log "Current step: #{current.inspect}"
    push_forward_step(current, position)
  end

  # Pushes a forward set of steps to the queue
  # @param current_step [RuneRb::Game::Map::Position] the current position
  # @param next_step [RuneRb::Game::Map::Position] the next position
  def push_forward_step(current_step, next_step)
    height = next_step[:z]
    delta_x = next_step[:x] - current_step[:x]
    delta_y = next_step[:y] - current_step[:y]

    # region_manager = @player.world[:region_manager]
    # region = region_manager.region_for_position(current_step)
    max = [delta_x.abs, delta_y.abs].max || delta_x.abs || 0

    log RuneRb::COL.green("Calculating #{max} steps")
    itr = 0
    max.times do
      itr += 1
      if delta_x < 0
        delta_x += 1
      elsif delta_x > 0
        delta_x -= 1
      end

      if delta_y < 0
        delta_y += 1
      elsif delta_y > 0
        delta_y -= 1
      end

      step = RuneRb::Game::Map::Position.new((next_step[:x] - delta_x),
                                       (next_step[:y] - delta_y),
                                       height)
      log RuneRb::COL.green("Added step #{itr} #{RuneRb::COL.yellow(step.inspect)}")
      @movement[:waypoints][:next] << step
    end
  end

  # Checks if there should be a Metas::CenterRegionFrame should be sent to update the context's region
  def region_change?
    delta_x = @position[:current][:x] - @position[:previous][:x]
    delta_y = @position[:current][:y] - @position[:previous][:y]
    delta_x < 16 || delta_x >= 86 || delta_y < 16 || delta_y >= 88
  end

  # The size of the queue
  def size
    @movement[:waypoints][:next].size
  end
end