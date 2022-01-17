Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'fileutils'
require 'fiber'
require 'singleton'
require 'socket'

##
# RuneRb -
#  A game server written in Ruby targeting the 2006 era (or the 317-377 protocols) of the popular MMORPG, RuneScape.
#
#
# @author Patrick W.
# @since 0.0.1
module RuneRb
  # @!attribute [r] GLOBAL
  # @return [Hash] a global map of key value pairs.
  GLOBAL = {}

  # Internal errors and objects.
  module System
    autoload :Controller,                     'system/controller'
    autoload :Environment,                    'system/environment'

    module Helpers
      autoload :Gateway,                      'system/helpers/gateway'
    end

    module Errors
      autoload :ConflictingNameError,         'system/errors'
      autoload :SessionReceptionError,        'system/errors'
    end
  end

  # Common Patches and Modules
  module Utils
    autoload :Logging,                        'utils/logging'

    module Patches
      autoload :IntegerRefinements,           'utils/patches/integer'
      autoload :SetRefinements,               'utils/patches/set'
      autoload :StringRefinements,            'utils/patches/string'
      autoload :StringIORefinements,          'utils/patches/stringio'
    end
  end
end

require_relative 'database/index'
require_relative 'game/index'
require_relative 'network/index'

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
