$LOAD_PATH.unshift(File.dirname(__FILE__), 'app')

require 'bundler/setup'
require 'rune.rb'

WORLD = RuneRb::World::World.new
SERVER = RuneRb::Server.new
SERVER.start_config({port: 43_594})