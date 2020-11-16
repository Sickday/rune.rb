# A module providing movement functionality to an Entity
module RuneRb::Entity::Movement
  # @return [Boolean] will this be running movement
  attr_accessor :running
  
  # @return [Hash] the directions of the movement module
  attr :directions

  # @return [Symbol] the current movement type
  attr :movement_type

  # Teleports the Mob to a new position.
  # @param to [RuneRb::Map::Position] the position to teleport to.
  def teleport(to)
    clear_waypoints
    @profile.location.set(to)
    @position = @profile.location.to_position
    @movement_type = :TELEPORT
    update(:teleport)
  end

  # Pushes a path to the queue
  # @param path [Array] an array of positions that make up the path
  def push_path(path)
    log "Adding path: #{path.inspect}"
    path.compact.each do |position|
      if path.first == position && waypoint_size.zero?
        push_primary_step(position)
      else
        push_step(position)
      end
    end
  end

  # The number of waypoints left in the movement path
  # @return [Integer] the number of steps left.
  def waypoint_size
    @next_waypoints.size
  end

  private

  # Initializes default parameters for the movement module
  # @param default_position [RuneRb::Map::Position] the default position to setup movement with.
  def setup_movement(default_position = RuneRb::Map::DEFAULT_POSITION)
    teleport(default_position)
    @regional = RuneRb::Map::Regional.from_position(@position)
    @next_waypoints = []
    @previous_waypoints = []
    @directions = { primary: RuneRb::Map::DIRECTIONS[:NONE],
                    secondary: RuneRb::Map::DIRECTIONS[:NONE],
                    previous: RuneRb::Map::DIRECTIONS[:NORTH] }
    @running = false
  end

  # Pulse through the queue
  def move
    pos = @position
    height = @position[:z]

    first_direction = RuneRb::Map::DIRECTIONS[:NONE]
    second_direction = RuneRb::Map::DIRECTIONS[:NONE]

    # world = @player.world
    # collision = @player.world[:collision_manager]

    next_point = @next_waypoints.shift
    log "Got 1st point #{next_point.inspect}" unless next_point.nil?

    unless next_point.nil?
      first_direction = RuneRb::Map::Direction.between(pos, next_point)
      log "Worked out 1st direction to be #{first_direction.inspect}"
      # Handle collision here
      @previous_waypoints << next_point
      pos = RuneRb::Map::Position.new(next_point[:x], next_point[:y], height)
      log 'Updated Pos.'
      @directions[:previous] = first_direction

      update(:move)
=begin
      if @running
        next_point = @next_waypoints.shift
        log "Got 2nd point #{next_point.inspect}"
        unless next_point.nil?
          second_direction = RuneRb::Map::Direction.between(pos, next_point)
          # Handle collision here
          @previous_waypoints << next_point
          pos = RuneRb::Map::Position.new(next_point[:x], next_point[:y], height)
          @directions[:previous] = second_direction
          @movement_type = :RUN
        end
      end
=end
    end

    @directions[:primary] = first_direction
    @directions[:secondary] = second_direction
    @position = next_point || pos
    @movement_type = :NONE if next_point.nil?
  end

  # Push the very first step into the queue
  # @param next_position [RuneRb::Map::Position] the next position.
  def push_primary_step(next_position)
    log "Adding primary position #{next_position.inspect}"
    @next_waypoints.clear
    @running = false

    backtrack = []
    log 'Populating backtrack'
    until @previous_waypoints.empty?
      pos = @previous_waypoints.pop
      backtrack << pos
      next unless pos.eql?(next_position)

      backtrack.each { |old| push_step(old) }
      @previous_waypoints.clear
      return
    end
    log 'Backtrack populated'

    @previous_waypoints.clear
    push_step(next_position)
  end

  # Push a step into the queue
  def push_step(position)
    current = @next_waypoints.last
    current ||= @position
    log "Current step: #{current.inspect}"
    push_forward_step(current, position)
  end

  # Pushes a forward set of steps to the queue
  # @param current_step [RuneRb::Map::Position] the current position
  # @param next_step [RuneRb::Map::Position] the next position
  def push_forward_step(current_step, next_step)
    next_x = next_step[:x]
    next_y = next_step[:y]
    height = next_step[:z]
    delta_x = next_x - current_step[:x]
    delta_y = next_y - current_step[:y]
    log "Deltas: [x: #{delta_x}, y: #{delta_y}]"

    max = [delta_x.abs, delta_y.abs].max || delta_x || 0
    log "Calculated max to be: #{max}."
    # region_manager = @player.world[:region_manager]
    # region = region_manager.region_for_position(current_step)

    max.times do
      if delta_x.negative?
        delta_x += 1
      elsif delta_x.positive?
        delta_x -= 1
      end

      if delta_y.negative?
        delta_y += 1
      elsif delta_y.positive?
        delta_y -= 1
      end

      step = RuneRb::Map::Position.new(next_x - delta_x, next_y - delta_y, height)
      log "Calculated step #{step.inspect}"
      # region = region_manager.region_for_position(step) unless region.has?(step)
      @next_waypoints << step
    end
    @movement_type = :WALK if max.positive?
  end

  # The size of the queue
  def size
    @next_waypoints.size
  end

  # Toggles the running mode for the queue.
  def toggle_run
    @running = true
  end

  # Clears the queue
  def clear_waypoints
    @next_waypoints&.clear
    @previous_waypoints&.clear
    @running = false
    @movement_type = :NONE
  end
end