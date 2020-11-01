require 'digest/crc32'
require 'bzip2/ffi'

module Cache
  autoload :Constants,       'constants'
  autoload :Descriptor,      'descriptor'
  autoload :Index,           'index'
  autoload :IndexedFS,       'indexed_fs'
end