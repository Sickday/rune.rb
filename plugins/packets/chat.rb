

# Chat
on_packet(4) do |player, packet|
  effect = packet.read_byte_s.ubyte
  color = packet.read_byte_s.ubyte
  size = packet.buffer.size

  # Prevent message flooding
  #next if player.chat_queue.size >= @@queue_size

  # Unpack string
  copy = RuneRb::Net::Packet.new(nil, nil, packet.buffer.clone)
  raw_data = copy.read_bytes(size).unpack('C' * size)
  chat_data = (0...size).collect { |i| (raw_data[size - i - 1] - 128).byte }
  message = RuneRb::Misc::TextUtils.unpack(chat_data, chat_data.size)
  message = RuneRb::Misc::TextUtils.filter(message)
  message = RuneRb::Misc::TextUtils.optimize(message)
  default = true
  HOOKS[:chat].each { |_k, v| default &= v.call(player, effect, color, message) != :nodefault }
  # Send to all clients
  if default
    packed = RuneRb::Misc::TextUtils.repack(size, packet)
    packed = packed.pack('C' * packed.size)
    player.chat_queue << RuneRb::Model::ChatMessage.new(color, effect, packed)
  end
end

# Command
on_packet(103) do |player, packet|
  command = packet.read_str
  params = Shellwords.shellwords command
  name = params[0].downcase
  params.shift
  begin
    handler = HOOKS[:command][name]
    handler.call(player, params) if handler.instance_of?(Proc)
  rescue StandardError => e
    player.io.send_message('Command error:')
    player.io.send_message($!.to_s)
    log = Logging.logger['packets']
    log.error 'Command error'
    log.error e
  end
end

# Disable chat if player is muted
on_chat(:mute) do |player, _effect, _color, _message|
  :nodefault if player.settings[:muted]
end

# Send message on login
on_player_login(:mute) do |player|
  player.io.send_message('You have been muted for breaking a rule.') if player.settings[:muted]
end

