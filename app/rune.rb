Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'oj'
require 'polyphony'
require 'socket'
require 'fiber'
require 'psych'
require 'pry'
require 'timers'

# RuneRb -
#  A game server written in Ruby targeting the 2006 era (or the 317-377 protocols) of the popular MMORPG, RuneScape.
#
#
# @author Patrick W.
# @since 0.9.3
module RuneRb

  GLOBAL = {}.tap do |config|
    config[:RAW] = Psych.load_file('assets/config/rune.rb.yml')
    config[:PROTOCOL] = config[:RAW]['GLOBAL']['PROTOCOL'].to_sym
    config[:REVISION] = config[:RAW]['GLOBAL']['PROTOCOL'].gsub('RS', '').to_i
  end

  load 'base/base.rb'
  load 'database/database.rb'
  load 'game/game.rb'

  Base::Utils::Logging.setup(GLOBAL)
  Database::Connection.setup(GLOBAL)
  Database::Connection.setup_game_datasets(GLOBAL, GLOBAL)
  Database::Connection.setup_item_datasets(GLOBAL, GLOBAL)
  Database::Connection.setup_mob_datasets(GLOBAL, GLOBAL)
  Database::Connection.setup_player_datasets(GLOBAL, GLOBAL)
  Game::World::Setup.setup_global_settings(GLOBAL)


  # Game-related objects, modules, and classes.


  # Network-related objects, models, and helpers.
  module Network
    autoload :Dispatcher,           'network/dispatcher'
    autoload :Endpoint,             'network/endpoint'
    autoload :Handshake,            'network/handshake'
    autoload :ISAAC,                'network/isaac'
    autoload :Message,              'network/message'
    autoload :Parser,               'network/parser'
    autoload :Session,              'network/session'
    autoload :Constants,            'network/constants'

    include Constants
  end
end

# Copyright (c) 2021, Patrick W.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.