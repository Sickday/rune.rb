module RuneRb::Game::Map
  class Point < Position
    attr_accessor :direction

    def initialize(x, y, direction)
      super(x, y)
      @direction = direction
    end

    def inspect
      "[x:#{@data[:x]},y:#{@data[:y]},direction:#{@direction}]"
    end

  end
  class Movement
    attr_accessor :running

    def initialize(entity)
      @player = entity
      @waypoints = []
      reset
    end

    def process
      # Acquire the next positions to move to
      walk_to = @waypoints.shift unless @waypoints.empty?
      run_to = @waypoints.shift if @running

      # Move the player
      if !walk_to.nil? && walk_to.direction != -1
        puts 'Got a walk_to'
        @player.position.move(RuneRb::Game::Map::X_DELTAS[walk_to.direction], RuneRb::Game::Map::Y_DELTAS[walk_to.direction])
        @player.movement[:primary_dir] = walk_to.direction
        @player.schedule(:move)
      end

      if !run_to.nil? && run_to.direction != -1
        @player.position.move(RuneRb::Game::Map::X_DELTAS[run_to.direction], RuneRb::Game::Map::Y_DELTAS[run_to.direction])
        @player.movement[:secondary_dir] = run_to.direction
      end

      delta_x = @player.position[:x] - @player.region.region_x * 8
      delta_y = @player.position[:y] - @player.region.region_y * 8
      return unless delta_x < 16 || delta_x > 88 || delta_y < 16 || delta_y > 88

      @player.flags[:region?] = true
      @player.update_region
    end

    def reset
      @waypoints.clear
      @running = false
      @current = @player.position
      @waypoints << Point.new(@current[:x], @current[:y], -1)
    end

    def push_position(position)
      reset if @waypoints.empty?

      last = @waypoints.last
      delta_x = position[:x] - last[:x]
      delta_y = position[:y] - last[:y]

      [delta_x, delta_y].max.times do

        delta_x += 1 if delta_x.negative?
        delta_x -= 1 if delta_x.positive?

        delta_y += 1 if delta_y.negative?
        delta_y -= 1 if delta_y.positive?

        push_step(position[:x] - delta_x,
                  position[:y] - delta_y)
      end
      puts inspect
    end

    def complete
      @waypoints.shift
    end

    def inspect
      @waypoints.inspect
    end

    def push_step(x, y)
      return if @waypoints.size >= 100

      last = @waypoints.last
      direction = RuneRb::Game::Map::Position.direction_for(x - last.data[:x],
                                                            y - last.data[:y])
      puts "Got direction #{direction}"
      @waypoints << Point.new(x, y, direction) if direction > -1
    end
  end
end