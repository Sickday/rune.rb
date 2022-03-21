module RuneRb::Network::RS317::MouseEventMessage

  # A mouse movement event
  Movement = Struct.new(:clicks, :x, :y, :delta?) do
    include RuneRb::Utils::Logging

    def inspect
      log! COLORS.blue("[CLICK_COUNT:] #{self.clicks}"),
           self.delta? ? COLORS.cyan.bold("[X:] #{self.x}") : COLORS.blue.bold("[X:] #{self.x}"),
           self.delta? ? COLORS.cyan.bold("[X:] #{self.x}") : COLORS.blue.bold("[X:] #{self.x}")
    end
  end

  # Parses the MouseEventMessage
  def parse(_)
    if @header[:length] == 2
      data = read_short
      return Movement.new(data >> 12, data >> 6 & 0x3f, data & 0x3f, true)
    elsif @header[:length] == 3
      data = read_medium & ~0x800000
    else
      data = read_int & ~0xc0000000
    end
    Movement.new(data >> 19, (data & 0x7f) % 765, (data & 0x7f) / 765).inspect
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