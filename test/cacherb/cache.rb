module CacheRb
  module FS
    require_relative 'fs/constants'
    include Constants

    autoload :Descriptor,     'fs/descriptor'
    autoload :Index,          'fs/index'
  end
end