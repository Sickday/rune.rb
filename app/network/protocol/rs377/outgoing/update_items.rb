module RuneRb::Network::RS377
  class UpdateItemsMessage < RuneRb::Network::Message

    # Constructs a new ContextInventoryMessage.
    # @param data [Hash] inventory data including items, amounts and corresponding slots
    def initialize(data)
      super('w', { op_code: 206 }, :VARIABLE_SHORT)

      # ContextInventoryForm ID
      write_short(3214)

      # Container length
      write_short(data[:size])

      data[:data].each do |_slot_id, item_stack|

        id = item_stack.nil? || item_stack.id.nil? || item_stack.id.negative? ? -1 : item_stack.id
        amount = item_stack.nil? || item_stack.size.nil? || item_stack.size.negative? ? 0 : item_stack.size

        write_short(id + 1, :ADD, :LITTLE)

        if amount > 254
          write_byte(0xFF, :NEGATE)
          write_int(amount, :STD, :LITTLE)
        else
          write_byte(amount, :NEGATE)
        end
      end
    end
  end
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