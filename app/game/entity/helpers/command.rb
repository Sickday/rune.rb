# Copyright (c) 2020, Patrick W.
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

module RuneRb::Game::Entity::Helpers::Command
  # Attempts to parse a command packet
  # @param message [RuneRb::Network::Message] the message to read from.
  def parse_command(message)
    command_string = message.read(:string).split(' ')
    label = command_string.shift
    log "Parsing command: #{label}" if RuneRb::GLOBAL[:DEBUG]
    command = fetch_command(label&.capitalize&.to_sym)
    if command
      command.new({ context: self, world: @world, message: message, command: command_string })
    else
      @session.write_message(:sys_message, message: "Could not parse Command: #{label.capitalize}")
    end
  rescue StandardError => e
    puts 'An error occurred during Command parsing'
    puts e
    puts e.backtrace
  end

  # Initializes the Instance#commands hash and populates it with recognizable commands.
  def load_commands
    @commands = {
      Animation: RuneRb::Game::Entity::Commands::Animation,
      Ban: RuneRb::Game::Entity::Commands::Ban,
      Graphic: RuneRb::Game::Entity::Commands::Graphic,
      Ascend: RuneRb::Game::Entity::Commands::Ascend,
      Descend: RuneRb::Game::Entity::Commands::Descend,
      Design: RuneRb::Game::Entity::Commands::Design,
      Position: RuneRb::Game::Entity::Commands::Position,
      Show: RuneRb::Game::Entity::Commands::Show,
      To: RuneRb::Game::Entity::Commands::To,
      Item: RuneRb::Game::Entity::Commands::Item
    }.freeze
  end

  # Attempts to fetch a registered Command object by it's label
  # @param label [Symbol, String] the label that will be used to fetch the Command
  # @return [RuneRb::Game::Entity::Command, FalseClass] returns the fetched Command object or nil.
  def fetch_command(label)
    @commands[label].nil? ? false : @commands[label]
  end
end