# encoding: utf-8

require 'coveralls'
require 'minitest'
require 'minitest/autorun'
require 'simplecov'

SimpleCov.start
Coveralls.wear!

require_relative '../../app/rune'
require_relative '../changes/constants'
require_relative '../changes/message/writeable'
require_relative '../changes/message/readable'
require_relative '../changes/message/message'
