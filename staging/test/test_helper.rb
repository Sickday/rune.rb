# encoding: utf-8

require 'minitest'
require 'minitest/autorun'
require 'simplecov'

SimpleCov.start

require_relative '../../app/rune'
require_relative '../changes/constants'
require_relative '../../app/network/message/writeable'
require_relative '../../app/network/message/readable'
require_relative '../../app/network/message/rb'
