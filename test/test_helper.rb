# encoding: utf-8

# Testing dependencies
require 'bundler/setup'
require 'minitest/autorun'
require 'simplecov'

# Require testing group gems
Bundler.require(:test)

# Launch Coverage
SimpleCov.start

# Load main index
require_relative '../lib/rune'

# Setup environment
RuneRb::Environment.init

# Useful lambdas
JUNK_DATA_FACTORY = -> { rand(0xFF..0xFFF).times.inject('') { _1 << [rand(-0xFF..0xFF)].pack('C')}.force_encoding(Encoding::BINARY) }
