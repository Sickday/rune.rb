# Interface to marshal objects as json strings.
module RuneRb::Types::Serializable
  attr :assets

  # Dumps the Serializable object into a string
  def dump
    Oj.dump(@assets)
  end

  # Retrieve asset by key
  # @param key [Object] the key assignment
  def [](key)
    @assets ||= {}
    @assets[key]
  end

  # Inserts a key value pair into the object's assets.
  # @param key [Object] the key assignment
  # @param value [Object] the associating object
  def []=(key, value)
    @assets ||= {}
    @assets[key] = value
  end
end