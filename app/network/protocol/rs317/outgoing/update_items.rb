module RuneRb::Network::RS317
  class UpdateItemsMessage < RuneRb::Network::Message

    # Constructs a new ContextInventoryMessage.
    # @param data [Hash] inventory data including items, amounts and corresponding slots
    def initialize(data)
      super(op_code: 53, type: :VARIABLE_SHORT)
      log! "Updating Inventory"

      # ContextInventoryForm ID
      write(3214, type: :short, order: 'BIG')

      # Container length
      write(data[:size], type: :short, order: 'BIG')

      data[:data].each do |_slot_id, item_stack|

        id = item_stack.nil? || item_stack.id.nil? || item_stack.id.negative? ? -1 : item_stack.id
        amount = item_stack.nil? || item_stack.size.nil? || item_stack.size.negative? ? 0 : item_stack.size

        if amount > 254
          write(0xFF, type: :byte)
          write(amount, type: :int, order: 'INVERSE_MIDDLE')
        else
          write(amount, type: :byte)
        end

        write(id + 1, type: :short, mutation: :ADD, order: 'LITTLE')
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