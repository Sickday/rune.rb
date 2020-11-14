Dir[File.dirname(__FILE__)].each { |file| $LOAD_PATH.unshift(file) }

require 'digest/crc32'
require 'bzip2/ffi'
require 'pry'

module RuneRb
  module Cache
    autoload :Constants,       'constants'
    autoload :Descriptor,      'descriptor'
    autoload :Index,           'index'
    autoload :IndexedFS,       'indexed_fs'
    autoload :MemoryArchive,   'mem_archive'
    autoload :PoorStream,      'stream'
    autoload :PoorStreamExtended, 'stream'

    module Definitions
      autoload :GameObject, 'g_object'
    end
  end
end
