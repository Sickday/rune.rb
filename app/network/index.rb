# frozen_string_literal: true

Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) if File.directory? file }
$LOAD_PATH.unshift File.dirname(__FILE__)

# Network-related objects, models, and helpers.
module RuneRb::Network
  autoload :Buffer,                                 'buffer'
  autoload :Constants,                              'constants'
  autoload :ISAAC,                                  'isaac'
  autoload :Message,                                'message'
  autoload :Session,                                'session'

  module Helpers
    autoload :Dispatcher,                           'helpers/dispatcher'
    autoload :Parser,                               'helpers/parser'
    autoload :Handshake,                            'helpers/handshake'
    autoload :Readable,                             'helpers/readable'
    autoload :NativeReadable,                       'helpers/native_readable'
    autoload :Writeable,                            'helpers/writeable'
    autoload :Validation,                           'helpers/validation'
  end

  # Messages compatible with the 317 protocol of RS.
  module RS317
    autoload :CenterRegionMessage,            'network/protocol/rs317/outgoing/center_region'
    autoload :ClearInterfacesMessage,         'network/protocol/rs317/outgoing/clear_interfaces'
    autoload :ContextStateBlock,              'network/protocol/rs317/outgoing/state'
    autoload :ContextSynchronizationMessage,  'network/protocol/rs317/outgoing/synchronization'
    autoload :DisplayInterfaceMessage,        'network/protocol/rs317/outgoing/interface'
    autoload :DisplaySidebarMessage,          'network/protocol/rs317/outgoing/sidebar'
    autoload :DisplayOverlayMessage,          'network/protocol/rs317/outgoing/overlay'
    autoload :LogoutMessage,                  'network/protocol/rs317/outgoing/logout'
    autoload :MembersAndIndexMessage,         'network/protocol/rs317/outgoing/membership_and_index'
    autoload :SystemTextMessage,              'network/protocol/rs317/outgoing/system_text'
    autoload :UpdateItemsMessage,             'network/protocol/rs317/outgoing/update_items'
    autoload :UpdateSlottedItemMessage,       'network/protocol/rs317/outgoing/update_slotted'
    autoload :StatUpdateMessage,              'network/protocol/rs317/outgoing/stat'

    autoload :ActionClickMessage,             'network/protocol/rs317/incoming/action'
    autoload :ArrowKeyMessage,                'network/protocol/rs317/incoming/arrow'
    autoload :ButtonClickMessage,             'network/protocol/rs317/incoming/button'
    autoload :PublicChatMessage,              'network/protocol/rs317/incoming/chat'
    autoload :MouseClickMessage,              'network/protocol/rs317/incoming/click'
    autoload :CommandMessage,                 'network/protocol/rs317/incoming/command'
    autoload :ContextDesignMessage,           'network/protocol/rs317/incoming/design'
    autoload :WindowFocusMessage,             'network/protocol/rs317/incoming/focus'
    autoload :HeartbeatMessage,               'network/protocol/rs317/incoming/heartbeat'
    autoload :MouseEventMessage,              'network/protocol/rs317/incoming/mouse'
    autoload :MovementMessage,                'network/protocol/rs317/incoming/movement'
    autoload :OptionClickMessage,             'network/protocol/rs317/incoming/option'
    autoload :PingMessage,                    'network/protocol/rs317/incoming/ping'
    autoload :SwitchItemMessage,              'network/protocol/rs317/incoming/switch'
  end

  # Messages compatible with the 377 protocol of RS.
  module RS377
    autoload :CenterRegionMessage,            'network/protocol/rs377/outgoing/center_region'
    autoload :ClearInterfacesMessage,         'network/protocol/rs377/outgoing/clear_interfaces'
    autoload :ContextSynchronizationMessage,  'network/protocol/rs377/outgoing/synchronization'
    autoload :ContextStateBlock,              'network/protocol/rs377/outgoing/state'
    autoload :DisplayInterfaceMessage,        'network/protocol/rs377/outgoing/interface'
    autoload :DisplayOverlayMessage,          'network/protocol/rs377/outgoing/overlay'
    autoload :DisplaySidebarMessage,          'network/protocol/rs377/outgoing/sidebar'
    autoload :LogoutMessage,                  'network/protocol/rs377/outgoing/logout'
    autoload :MembersAndIndexMessage,         'network/protocol/rs377/outgoing/membership_and_index'
    autoload :SystemTextMessage,              'network/protocol/rs377/outgoing/system_text'
    autoload :UpdateItemsMessage,             'network/protocol/rs377/outgoing/update_items'
    autoload :UpdateSlottedItemMessage,       'network/protocol/rs377/outgoing/update_slotted'
    autoload :StatUpdateMessage,              'network/protocol/rs377/outgoing/stat'

    autoload :ActionClickMessage,             'network/protocol/rs377/incoming/action'
    autoload :ArrowKeyMessage,                'network/protocol/rs377/incoming/arrow'
    autoload :ButtonClickMessage,             'network/protocol/rs377/incoming/button'
    autoload :PublicChatMessage,              'network/protocol/rs377/incoming/chat'
    autoload :MouseClickMessage,              'network/protocol/rs377/incoming/click'
    autoload :CommandMessage,                 'network/protocol/rs377/incoming/command'
    autoload :ContextDesignMessage,           'network/protocol/rs377/incoming/design'
    autoload :WindowFocusMessage,             'network/protocol/rs377/incoming/focus'
    autoload :HeartbeatMessage,               'network/protocol/rs377/incoming/heartbeat'
    autoload :MouseEventMessage,              'network/protocol/rs377/incoming/mouse'
    autoload :MovementMessage,                'network/protocol/rs377/incoming/movement'
    autoload :OptionClickMessage,             'network/protocol/rs377/incoming/option'
    autoload :PingMessage,                    'network/protocol/rs377/incoming/ping'
    autoload :SwitchItemMessage,              'network/protocol/rs377/incoming/switch'
  end
end