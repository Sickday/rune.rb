require 'async'

require_relative 'client'


client = Client::Instance.new(rand(1 << 8))
client.login