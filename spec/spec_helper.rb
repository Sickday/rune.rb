# encoding: utf-8

# Testing Dependencies
require 'bundler/setup'
require 'pry'

# Require testing group gems
Bundler.require(:test)

# Start coverage
SimpleCov.start

# Include RSpec module
include RSpec

# Load main index file
require_relative '../lib/rune'

# Setup environment
RuneRb::System::Environment.init

# Useful lambdas
JUNK_DATA_FACTORY = -> { rand(0xFF..0xFFF).times.inject('') { _1 << [rand(-0xFF..0xFF)].pack('C')}.force_encoding(Encoding::BINARY) }