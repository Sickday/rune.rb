module RuneRb::Base

  # A basic error produced by the RuneRb base application.
  class Error < StandardError
    include RuneRb::Base::Utils::Logging

    attr :message

    def initialize(interests = {}, msg = "")
      @message = msg
      err @message, "Raised by: #{RuneRb::GLOBAL[:COLOR].red(interests)}"
    end
  end

  # Namespace for all errors
  module Errors

    # Raised when a Session is not received by a RuneRb::Game::World::Instance
    class SessionReceptionError < RuneRb::Base::Error
      def initialize(type, expected, received)
        case type
        when :banned then super(received, "#{received} is banned from this network!")
        when :op_code then super(received, "Unrecognized operation code received in handshake!\t[Expected:] #{RuneRb::GLOBAL[:COLOR].green.bold(expected)}, [Received:] #{RuneRb::GLOBAL[:COLOR].red.bold(received)}")
        when :seed then super(received, "Mismatched seed received in handshake!\t[Expected:] #{RuneRb::GLOBAL[:COLOR].green.bold(expected)}, [Received:] #{RuneRb::GLOBAL[:COLOR].red.bold(received)}")
        when :magic then super(received,"Unexpected Magic received in handshake!\t[Expected:] #{RuneRb::GLOBAL[:COLOR].green.bold(expected)}, [Received:] #{RuneRb::GLOBAL[:COLOR].red.bold(received)}")
        when :username then super(received,"Invalid Username in handshake!\t[Received:] #{RuneRb::GLOBAL[:COLOR]::red.bold(received)}")
        when :password then super(received, 'Incorrect Password in handshake!')
        when :revision then super(received,"Incompatible revision received in handshake!\t[Received:] #{RuneRb::GLOBAL[:COLOR]::red.bold(received)}")
        else super(received,"Unspecified SessionReceptionError! [Type: #{type.inspect}][Ex: #{RuneRb::GLOBAL[:COLOR].green.bold(expected)}][Rec: #{RuneRb::GLOBAL[:COLOR].red.bold(received)}]")
        end
      end
    end

    # Raised when a name conflict occurs.
    class ConflictingNameError < RuneRb::Base::Error
      def initialize(type, received)
        case type
        when :banned_name then super(received,"Appended banned name already exists in database!\t[Received:] #{RuneRb::GLOBAL[:COLOR].red.bold(received)}")
        when :username then super(received,"A profile with this Username already exists in database!\t[Received:] #{RuneRb::GLOBAL[:COLOR]::red.bold(received)}")
        else super(received,"Unspecified ConflictingNameError! [Type: #{type.inspect}][Rec: #{RuneRb::GLOBAL[:COLOR].red.bold(received)}]")
        end
      end
    end

    class UnrecognizedMessage < RuneRb::Base::Error
      def initialize(message)
        super(message, "Unrecognized message received from client! OpCode: #{message.header[:op_code]}, Len: #{message.header[:length]}")
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