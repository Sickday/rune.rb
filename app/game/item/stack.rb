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

module RuneRb::Game::Item
  # Represents a stack of items.
  class Stack
    attr :definition, :id
    attr_accessor :size

    # Called when a new ItemStack is created.
    # @param id [Integer] the id of the Item
    # @param amount [Integer] the initial amount of the stack.
    def initialize(id, amount = 1)
      @id = id
      @definition = RuneRb::System::Database::Item[id]
      @size = amount
    end

    # Returns serialized dump of this Stack.
    # @return [String] A dump of this Stack
    def to_json(*_args)
      RuneRb::Game::Item::Stack.dump(self)
    end

    # An inspection of the Stack's definition.
    def inspect
      @definition.inspect
    end

    class << self
      # Returns a serialized dump of the passed Stack object.
      # @param stack [RuneRb::Game::Item::Stack] the Stack to dump
      def dump(stack)
        Oj.dump({ id: stack.id, amount: stack.size }, mode: :compat, use_as_json: true)
      end

      # Restores a serialized dump of a Stack object.
      # @param data [Hash] a serialized dump
      def restore(data)
        RuneRb::Game::Item::Stack.new(data[:id], data[:amount])
      end
    end
  end
end