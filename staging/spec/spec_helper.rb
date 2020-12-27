# encoding: utf-8

require 'coveralls'
require 'rspec'
require 'simplecov'

SimpleCov.start
Coveralls.wear!
include RSpec

require_relative '../../app/rune'
require_relative '../changes/channel'
require_relative '../changes/constants'
require_relative '../changes/message/writeable'
require_relative '../changes/message/readable'
require_relative '../changes/message/message'
