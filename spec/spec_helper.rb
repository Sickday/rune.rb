# encoding: utf-8

require 'coveralls'
require 'rspec'
require 'simplecov'
require 'faker'

SimpleCov.start
Coveralls.wear!

include RSpec

require_relative '../app/rune'
