# encoding: utf-8

require 'coveralls'
require 'minitest'
require 'minitest/autorun'
require 'simplecov'

SimpleCov.start
Coveralls.wear!

require_relative '../app/rune'
