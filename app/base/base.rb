Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'druuid'
require 'fiber'
require 'fileutils'
require 'logger'
require 'pastel'
require 'psych'
require 'set'
require 'singleton'

# RuneRb -
#  A game server written in Ruby targeting the 2006 era (or the 317-377 protocols) of the popular MMORPG, RuneScape.
#
#
# @author Patrick W.
# @since 0.9.3
module RuneRb

	# The base package for the RuneRb application.
	module Base

		# Refinements made to objects already defined in the stdlib/core lib. The refinements are used in the objects who require the functions defined in the refinement. Doing this prevents pollution of the global definitions of the stdlib objects.
		module Patches
			autoload :IntegerRefinements,               'base/patches/integer'
			autoload :SetRefinements,                   'base/patches/set'
			autoload :StringRefinements,                'base/patches/string'
			autoload :Readable,                         'base/patches/readable'
			autoload :LegacyReadable,										'base/patches/legacy_readable'
			autoload :Writeable,                        'base/patches/writeable'
		end

		# Utility functions and objects used throughout the framework.
		module Utils
			autoload :Constants,                        'base/utils/constants'
			autoload :Logging,                          'base/utils/log'
			autoload :Error,                            'base/utils/errors'
		end

		# Objects which are raised when certain conditions are met, interrupting the execution of code which triggered the object.
		autoload :Error,															'base/utils/errors'

		module Errors
			autoload :UnrecognizedMessage,							'base/utils/errors'
			autoload :SessionReceptionError,						'base/utils/errors'
			autoload :ConflictingNameError,							'base/utils/errors'
		end

		# Basic object types unique to RuneRb and used throughout the framework.
		module Types
			autoload :Message,                          'base/types/message'
			autoload :Routine,                          'base/types/routine'
			autoload :Controller,                       'base/types/controller'
		end

		# In/out objects related to RS protocols.
		module IO

			# Messages compatible with the 317 protocol of RS.
			module RS317
				autoload :CenterRegionMessage,            'base/io/rs317/outgoing/center_region'
				autoload :ClearInterfacesMessage,         'base/io/rs317/outgoing/clear_interfaces'
				autoload :ContextStateBlock,              'base/io/rs317/outgoing/state'
				autoload :ContextSynchronizationMessage,  'base/io/rs317/outgoing/synchronization'
				autoload :DisplayInterfaceMessage,        'base/io/rs317/outgoing/interface'
				autoload :DisplaySidebarMessage,          'base/io/rs317/outgoing/sidebar'
				autoload :DisplayOverlayMessage,          'base/io/rs317/outgoing/overlay'
				autoload :LogoutMessage,                  'base/io/rs317/outgoing/logout'
				autoload :MembersAndIndexMessage,         'base/io/rs317/outgoing/membership_and_index'
				autoload :SystemTextMessage,              'base/io/rs317/outgoing/system_text'
				autoload :UpdateItemsMessage,             'base/io/rs317/outgoing/update_items'
				autoload :UpdateSlottedItemMessage,       'base/io/rs317/outgoing/update_slotted'
				autoload :StatUpdateMessage,              'base/io/rs317/outgoing/stat'

				autoload :ActionClickMessage,             'base/io/rs317/incoming/action'
				autoload :ArrowKeyMessage,                'base/io/rs317/incoming/arrow'
				autoload :ButtonClickMessage,             'base/io/rs317/incoming/button'
				autoload :PublicChatMessage,              'base/io/rs317/incoming/chat'
				autoload :MouseClickMessage,              'base/io/rs317/incoming/click'
				autoload :CommandMessage,                 'base/io/rs317/incoming/command'
				autoload :ContextDesignMessage,           'base/io/rs317/incoming/design'
				autoload :WindowFocusMessage,             'base/io/rs317/incoming/focus'
				autoload :HeartbeatMessage,               'base/io/rs317/incoming/heartbeat'
				autoload :MouseEventMessage,              'base/io/rs317/incoming/mouse'
				autoload :MovementMessage,                'base/io/rs317/incoming/movement'
				autoload :OptionClickMessage,             'base/io/rs317/incoming/option'
				autoload :PingMessage,                    'base/io/rs317/incoming/ping'
				autoload :SwitchItemMessage,              'base/io/rs317/incoming/switch'
			end

			# Messages compatible with the 377 protocol of RS.
			module RS377
				autoload :CenterRegionMessage,            'base/io/rs377/outgoing/center_region'
				autoload :ClearInterfacesMessage,         'base/io/rs377/outgoing/clear_interfaces'
				autoload :ContextSynchronizationMessage,  'base/io/rs377/outgoing/synchronization'
				autoload :ContextStateBlock,              'base/io/rs377/outgoing/state'
				autoload :DisplayInterfaceMessage,        'base/io/rs377/outgoing/interface'
				autoload :DisplayOverlayMessage,          'base/io/rs377/outgoing/overlay'
				autoload :DisplaySidebarMessage,          'base/io/rs377/outgoing/sidebar'
				autoload :LogoutMessage,                  'base/io/rs377/outgoing/logout'
				autoload :MembersAndIndexMessage,         'base/io/rs377/outgoing/membership_and_index'
				autoload :SystemTextMessage,              'base/io/rs377/outgoing/system_text'
				autoload :UpdateItemsMessage,             'base/io/rs377/outgoing/update_items'
				autoload :UpdateSlottedItemMessage,       'base/io/rs377/outgoing/update_slotted'
				autoload :StatUpdateMessage,              'base/io/rs377/outgoing/stat'

				autoload :ActionClickMessage,             'base/io/rs377/incoming/action'
				autoload :ArrowKeyMessage,                'base/io/rs377/incoming/arrow'
				autoload :ButtonClickMessage,             'base/io/rs377/incoming/button'
				autoload :PublicChatMessage,              'base/io/rs377/incoming/chat'
				autoload :MouseClickMessage,              'base/io/rs377/incoming/click'
				autoload :CommandMessage,                 'base/io/rs377/incoming/command'
				autoload :ContextDesignMessage,           'base/io/rs377/incoming/design'
				autoload :WindowFocusMessage,             'base/io/rs377/incoming/focus'
				autoload :HeartbeatMessage,               'base/io/rs377/incoming/heartbeat'
				autoload :MouseEventMessage,              'base/io/rs377/incoming/mouse'
				autoload :MovementMessage,                'base/io/rs377/incoming/movement'
				autoload :OptionClickMessage,             'base/io/rs377/incoming/option'
				autoload :PingMessage,                    'base/io/rs377/incoming/ping'
				autoload :SwitchItemMessage,              'base/io/rs377/incoming/switch'
			end
		end
	end

	include Base::Utils::Constants
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