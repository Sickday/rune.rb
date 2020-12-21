module Setup
  ##
  # INITIALIZES GLOBAL SETTINGS
  begin
    GLOBAL = {}.tap do |settings|
      Oj.load(File.read('assets/config/rune.rb.json')).each do |key, value|
        settings[key.to_sym] = value
      end
    end

    GLOBAL[:RRB_STORAGE] = GLOBAL[:RRB_STORAGE].to_sym
  rescue StandardError => e
    puts "An error occurred while loading Global settings!"
    puts e
    puts e.backtrace
    exit
  end

  ##
  # INITIALIZE LOGGER
  begin
    if GLOBAL[:RRB_LOGS_PATH]
      # Set the logfile path.
      LOG_FILE_PATH = GLOBAL[:RRB_LOGS_PATH]
    else
      # Create the asset log folder if it does not exist.
      FileUtils.mkdir_p("#{FileUtils.pwd}/assets/log")
      LOG_FILE_PATH = "#{FileUtils.pwd}/assets/log/rune_rb-#{Time.now.strftime('%Y-%m-%d').chomp}.log"
    end
    # Initialize a new log file
    LOG_FILE = Logger.new(LOG_FILE_PATH, progname: GLOBAL[:RRB_TITLE])
    # Initialize a new logger
    LOG = Console.logger
    # Log Coloring
    COL = Pastel.new
  rescue StandardError => e
    puts "An error occurred while initializing logger!"
    puts e
    puts e.backtrace
    exit
  end

  ###
  # INITIALIZE DATABASE CONNECTION
  begin
    case GLOBAL[:RRB_STORAGE]
    when :sqlite
      # A connection to the sqlite database
      CONNECTION = Sequel.sqlite(GLOBAL[:SQLITE_DATABASE])
      # A dataset containing player appearances.
      PLAYER_APPEARANCES = CONNECTION[:appearance]
      # A dataset containing player profiles.
      PLAYER_PROFILES = CONNECTION[:profile]
      # A dataset containing player location information.
      PLAYER_LOCATIONS = CONNECTION[:location]
      # A dataset containing player setting information.
      PLAYER_SETTINGS = CONNECTION[:settings]
      # A dataset containing player stats.
      PLAYER_STATS = CONNECTION[:stats]
      # A dataset containing player status information.
      PLAYER_STATUS = CONNECTION[:status]
      # A dataset containing Item definitions.
      ITEM_DEFINITIONS = CONNECTION[:items]
      # A dataset containing banned names.
      BANNED_NAMES = CONNECTION[:banned_names]
      # A dataset containing snapshots.
      SNAPSHOTS = CONNECTION[:snapshots]
    when :postgres
      # A connection to the Profiles database
      PROFILES = Sequel.postgres(GLOBAL[:PROFILE_DATABASE], user: GLOBAL[:DATABASE_USER], password: GLOBAL[:DATABASE_PASS], host: GLOBAL[:DATABASE_HOST], port: GLOBAL[:DATABASE_PORT])
      # A connection to the Systems database
      SYSTEMS = Sequel.postgres(GLOBAL[:SYSTEM_DATABASE], user: GLOBAL[:DATABASE_USER], password: GLOBAL[:DATABASE_PASS], host: GLOBAL[:DATABASE_HOST], port: GLOBAL[:DATABASE_PORT])
      # A connection to the Definitions database.
      DEFINITIONS = Sequel.postgres(GLOBAL[:DEFINITIONS_DATABASE], user: GLOBAL[:DATABASE_USER], password: GLOBAL[:DATABASE_PASS], host: GLOBAL[:DATABASE_HOST], port: GLOBAL[:DATABASE_PORT])
      # A dataset containing player appearances.
      PLAYER_APPEARANCES = PROFILES[:appearance]
      # A dataset containing player profiles.
      PLAYER_PROFILES = PROFILES[:profile]
      # A dataset containing player locations.
      PLAYER_LOCATIONS = PROFILES[:location]
      # A dataset containing player settings.
      PLAYER_SETTINGS = PROFILES[:settings]
      # A dataset containing player stats.
      PLAYER_STATS = PROFILES[:stats]
      # A dataset containing player status information.
      PLAYER_STATUS = PROFILES[:status]
      # A dataset containing Item Definitions
      ITEM_DEFINITIONS = DEFINITIONS[:items]
      # A dataset containing banned names.
      BANNED_NAMES = SYSTEMS[:banned_names]
      # A dataset containing snapshots.
      SNAPSHOTS = SYSTEMS[:snapshots]
    end
  rescue StandardError => e
    puts "An error occurred while initializing datasets!"
    puts e
    puts e.backtrace
    exit
  end
end