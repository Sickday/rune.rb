$:.unshift File.join(File.dirname(__FILE__), "lib")

require 'bundler/setup'
require 'rune.rb'

WORLD = RuneRb::World::World.new
SERVER = RuneRb::Server.new
SERVER.start_config(RuneRb::Misc::HashWrapper.new({:port => 43594}))