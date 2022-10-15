# frozen_string_literal: true

require 'sequel/plugins/serialization'
require 'sequel/plugins/serialization_modification_detection'

# A module responsible for setting up the execution environment for RuneRb.
module RuneRb::Environment
  extend self

  def init(path = '.')
    Dotenv.load(File.exist?(path) ? "#{path}/.env" : '.env')
    # RuneRb.const_set(:ENV, init_env) unless RuneRb.const_defined?(:ENV)
    RuneRb.const_set(:LOGGER, init_logger) unless RuneRb.const_defined?(:LOGGER)
    RuneRb.const_set(:DATABASE, init_database) unless RuneRb.const_defined?(:DATABASE)
    # RuneRb.const_set(:CACHE, init_cache) unless RuneRb.const_defined?(:CACHE)
  end

  private

  # A struct for logging objects.
  # @return [Struct]
  Log = Struct.new(:stdout, :file, :colors)

  # Initializes a global logger.
  # @param path [String] the path to store logs in.
  # @param config [Hash] the configuration map used to setup the logger.
  # @return [Log] the initialized GameLogger
  def init_logger(path = 'data/logs', config = ENV)
    FileUtils.mkdir_p(path) unless File.exist?(path)

    logger = Log.new
    logger.stdout = Logger.new($stdout)
    logger.file = Logger.new("#{path}/rune.rb-#{RuneRb.const_defined?(:VERSION) ? RuneRb::VERSION.build : '0.0.1-mystery_box'}-#{Time.now.strftime('%Y-%m-%d').chomp}.log", progname: config['RRB_LABEL'] || 'rune.rb')
    logger.colors = Pastel.new
    logger.stdout.formatter = proc do |sev, date, _prog, msg|
      "#{logger.colors.cyan("[#{date.strftime('%H:%M')}]")}|#{logger.colors.blue("[#{sev}]")} -> #{msg}\n"
    end
    logger
  rescue StandardError => e
    if RuneRb::LOGGER
      RuneRb::LOGGER.stdout.error('rune.rb') { "[#{Time.now.strftime('[%H:%M')}] [LoggerSetup] ~> A fatal error occurred while initializing a global Logger!" }
      RuneRb::LOGGER.stdout.error('rune.rb') { "[#{Time.now.strftime('[%H:%M')}] [LoggerSetup] ~> #{e}" }
      RuneRb::LOGGER.stdout.error('rune.rb') { "[#{Time.now.strftime('[%H:%M')}] [LoggerSetup] ~> #{e.message}" }
      RuneRb::LOGGER.stdout.error('rune.rb') { "[#{Time.now.strftime('[%H:%M')}] [LoggerSetup] ~> #{e.backtrace&.join("\n")}" }
    else
      puts '[LoggerSetup] A global GameLogger is uninitialized!'
      puts "[LoggerSetup] A fatal error occurred while initializing a global Logger!\n#{e}"
      puts e.message
      puts e.backtrace&.join("\n")
    end
  end

  # A struct for world configuration.
  # @return [Struct]
  WorldConfiguration = Struct.new(:raw, :max_mobs, :max_contexts, :login_limit) do

    def load_world_config
      self.max_mobs = raw['RRB_GAME_MAX_MOBS']&.to_i || 256
      self.max_contexts = raw['RRB_GAME_MAX_CTX']&.to_i || 256
      self.login_limit = raw['RRB_GAME_LOGIN_LIMIT']&.to_i || 4
    end
  end

  # A struct for server configuration.
  # @return [Struct]
  ServerConfiguration = Struct.new(:raw, :host, :port, :revision, :protocol) do

    def load_server_config
      self.host = raw['RRB_NET_HOST'] || 'localhost'
      self.port = raw['RRB_NET_PORT']&.to_i || 43594
      self.protocol = raw['RRB_NET_PROTOCOL']&.to_i || 317
      self.revision = raw['RRB_NET_PROTOCOL'].nil? ? :RS317 : "RS#{protocol}".to_sym
    end
  end

  # A struct for global configuration.
  # @return [Struct]
  GlobalConfiguration = Struct.new(:raw, :version, :build, :live, :debug, :world_config, :server_config) do
    # Loads the raw ENV from an existing file or downloads a sample env and loads that.
    # @param path [String] the path to the `.rune.rb.env` file
    def load_env
      self.raw = Dotenv.load(File.exist?(path) ? path : 'data/sample-rrb.env')
      self.live = raw['RRB_LIVE']&.to_i&.positive? || false
      self.debug = raw['RRB_DEBUG']&.to_i&.positive? || false
    end

    # Loads versioning details for RuneRb.
    def load_version
      version_req = HTTP.get("http://db.objects.pw:32960/api/v1/project/#{raw['RRB_PROJECT_SIGNATURE']}").parse
      self.version = version_req[':version']
      self.build = "#{version_req[':version']}-#{version_req[':build']}"
    end
  end

  # Initialize the execution environment for RuneRb.
  # @return [GlobalConfiguration] the initialized GameConfiguration.
  def init_env
    configuration = GlobalConfiguration.new
    configuration.load_env
    configuration.load_version

    configuration.server_config = ServerConfiguration.new
    configuration.server_config.load_server_config

    configuration.world_config = WorldConfiguration.new
    configuration.world_config.load_world_config
    configuration
  rescue StandardError => e
    if RuneRb::LOGGER
      RuneRb::LOGGER.stdout.error do
        ["[#{Time.now.strftime('[%H:%M')}] [ConfigSetup] ~> A fatal error occurred while initializing a global Configuration!",
         "[#{Time.now.strftime('[%H:%M')}] [ConfigSetup] ~> #{e}",
         "[#{Time.now.strftime('[%H:%M')}] [ConfigSetup] ~> #{e.message}",
         "[#{Time.now.strftime('[%H:%M')}] [ConfigSetup] ~> #{e.backtrace&.join("\n")}"].join("\n")
      end
    else
      puts ['[ConfigSetup] A global Logger is uninitialized!',
            "[ConfigSetup] A fatal error occurred while initializing a global Configuration!\n#{e}",
            e.message, e.backtrace&.join("\n")].join("\n")
    end
  end

  DatabaseConfiguration = Struct.new(:raw, :player, :system, :game) do

    def load_config(path: '.rrb.db.env')
      self.raw = Dotenv.load(File.exist?(path) ? path : 'data/sample-rrb.db.env')
      case self.raw['RRB_STORAGE_TYPE']
        when 'sqlite'
          self.player = Sequel.sqlite(raw['RRB_PLAYER_SQLITE_PATH'] || 'data/sample-rrb-player.sqlite', pragmata: :foreign_keys, logger: RuneRb::GLOBAL[:LOGGER].file)
          self.game = Sequel.sqlite(raw['RRB_GAME_SQLITE_PATH'] || 'data/sample-rrb-game.sqlite', pragmata: :foreign_keys, logger: RuneRb::GLOBAL[:LOGGER].file)
          self.system = Sequel.sqlite(raw['RRB_SYSTEM_SQLITE_PATH'] || 'data/sample-rrb-system.sqlite', pragmata: :foreign_keys, logger: RuneRb::GLOBAL[:LOGGER].file)
        when 'pg', 'postgresql', 'postgres'
          # Model plugin for JSON serialization
          Sequel::Model.plugin(:json_serializer)
          self.player = self.game = self.system = Sequel.postgres(host: raw['RRB_PG_HOST'], port: raw['RRB_PG_PORT'],
                                                                  user: raw['RRB_PG_USER'], password: raw['RRB_PG_PASS'],
                                                                  database: raw['RRB_PG_DB'], logger: RuneRb::GLOBAL[:LOGGER].file)
      end
    end
  end

  def init_database
    database = DatabaseConfiguration.new
    database.load_config
    database
  rescue StandardError => e
    if RuneRb::GLOBAL[:LOGGER]
      RuneRb::GLOBAL[:LOGGER].stdout.error('rune.rb-data') { "[#{Time.now.strftime('[%H:%M')}] [DatabaseSetup] ~> A fatal error occurred while initializing a global Database!" }
      RuneRb::GLOBAL[:LOGGER].stdout.error('rune.rb-data') { "[#{Time.now.strftime('[%H:%M')}] [DatabaseSetup] ~> #{e}" }
      RuneRb::GLOBAL[:LOGGER].stdout.error('rune.rb-data') { "[#{Time.now.strftime('[%H:%M')}] [DatabaseSetup] ~> #{e.message}" }
      RuneRb::GLOBAL[:LOGGER].stdout.error('rune.rb-data') { "[#{Time.now.strftime('[%H:%M')}] [DatabaseSetup] ~> #{e.backtrace&.join("\n")}" }
    else
      puts '[DatabaseSetup] A global GameLogger is uninitialized!'
      puts "[DatabaseSetup] A fatal error occurred while initializing a global Database!\n#{e}"
      puts e.message
      puts e.backtrace&.join("\n")
    end
  end
end
