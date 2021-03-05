# encoding: utf-8

require 'rspec'
require 'simplecov'

SimpleCov.start
include RSpec

require_relative '../../app/rune'
require_relative '../changes/channel'
require_relative '../changes/constants'
require_relative '../../app/network/message/writeable'
require_relative '../../app/network/message/readable'
require_relative '../../app/network/message/rb'
