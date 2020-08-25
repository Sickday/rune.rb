Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }

require 'console'
require 'dotenv/load'
require 'fileutils'
require 'logger'
require 'socket'
require 'set'
require 'pastel'
require 'polyphony'
require 'psych'

##
# A small framework for server applications
module Scratch
  autoload :Utils,                    'util/misc'

  ##
  # Scratch::Core
  module Core
    autoload :Scheduler,              'components/scheduler'
  end

  ##
  # Scratch::Types
  module Types
    autoload :OperationChain,         'types/operation_chain'
    autoload :Routine,                'types/routine'
  end

  # Set the logfile path.
  LOG_FILE_PATH = ENV['LOG_FILE_PATH'] || "#{FileUtils.pwd}/assets/log/SFW-#{Time.now.strftime('%Y-%m-%d').chomp}.log".freeze
  FileUtils.mkdir_p("#{FileUtils.pwd}/assets/log")

  # Initialize a new log file
  LOG_FILE = Logger.new(LOG_FILE_PATH, progname: 'SFW')
  # Initialize a new logger
  LOG = Console.logger
  COL = Pastel.new
end