module RuneRb
  class Server
    attr :config
    attr :cache
    attr_accessor :updatemode
    attr_accessor :max_players

    def initialize
      @updatemode = false
      @max_players = 1000
      setup_logger
    end

    def setup_logger
      Logging.color_scheme('bright',
                           levels: {
                               info: :green,
                               warn: :yellow,
                               error: :red,
                               fatal: %i[white on_red]
                           },
                           date: :white,
                           logger: :white,
                           message: :white)

      Logging.logger.root.add_appenders(
          Logging.appenders.stdout(
              'stdout',
              layout: Logging.layouts.pattern(
                  pattern: '[%d] %-5l %c: %m\n',
                  color_scheme: 'bright')
          ),
          Logging.appenders.file('data/logs/development.log', layout: Logging.layouts.pattern(pattern: '[%d] %-5l %c: %m\n'))
      )

      @log = Logging.logger['server']
    end

    def start_config(config)
      @config = config
      init_cache
      load_int_hooks
      load_defs
      load_hooks
      load_config
      bind
    end

    def reload
      HOOKS.clear
      load_hooks
      load_int_hooks
      RuneRb::Net.load_packets
    end

    # Load hooks
    def load_hooks
      Dir['./plugins/*.rb'].each { |file| load file }
    end

    def load_int_hooks
      Dir['./plugins/internal/*.rb'].each { |file| load file }
    end

    def init_cache
      @cache = RuneRb::Misc::Cache.new('./data/cache/')
    rescue StandardError => e
      Logging.logger['cache'].warn(e.to_s)
    end

    def load_defs
      RuneRb::Item::ItemDefinition.load

      # Equipment
      RuneRb::Equipment.load
    end

    def load_config
      WORLD.shop_manager.load_shops
      WORLD.door_manager.load_single_doors
      WORLD.door_manager.load_double_doors

      RuneRb::World::NPCSpawns.load
      RuneRb::World::ItemSpawns.load
    end

    # Binds the server socket and begins accepting player connections.
    def bind
      EventMachine.run do
        Signal.trap('INT') do
          WORLD.players.each { |p| WORLD.unregister(p) } ## TODO: Smells bad. Make this a function of the WORLD obj at least.
          sleep(0.01) while WORLD.work_thread.waiting.positive? ## OOF.
          EventMachine.stop if EventMachine.reactor_running?
          exit
        end

        Signal.trap('TERM') { EventMachine.stop }

        EventMachine.start_server('0.0.0.0', @config.port + 1, RuneRb::Net::JaggrabConnection) if @cache
        EventMachine.start_server('0.0.0.0', @config.port, RuneRb::Net::Connection)
        @log.info "Ready on port #{@config.port}"
      end
    end
  end
end
