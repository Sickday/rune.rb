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

module RuneRb::Network::Constants
  # A map of valid connection types
  CONNECTION_TYPES = {
    GAME_RECONNECT: 18,
    GAME_ONLINE: 16,
    GAME_UPDATE: 15,
    GAME_LOGIN: 14
  }.freeze

  # @return [Hash] a map of response codes and symbol keys indicative of their meaning.
  LOGIN_RESPONSES = { RETRY_COUNT: -1, OK: 0, RETRY: 1, SUCCESS: 2,
                      BAD_CREDENTIALS: 3, BANNED_ACCOUNT: 4, CONFLICTING_SESSION: 5,
                      INVALID_REVISION: 6, WORLD_IS_FULL: 7, LOGIN_OFFLINE: 8,
                      TOO_MANY_CONNECTIONS: 9, BAD_SESSION_ID: 10, REJECTED_SESSION: 11,
                      NON_MEMBERS: 12, WORLD_OFFLINE: 13, UPDATE_IN_PROGRESS: 14,
                      TOO_MANY_ATTEMPTS: 16, BAD_POSITION: 17, BAD_LOGIN_SERVER: 20,
                      WORLD_TRANSFER: 21 }.freeze

  # A map of sidebar interface menu_ids -> form ids
  SIDEBAR_INTERFACES = { 0 => 2423, # ATTACK
                         1 => 3917, # SKILL
                         2 => 638,  # QUEST
                         3 => 3213, # INVENT
                         4 => 1644, # EQUIPMENT
                         5 => 5608, # PRAYER
                         6 => 1151, # NORMAL SPELLS = 1151, ANCIENT = 12855
                         8 => 5065, # FRIENDS
                         9 => 5715, # IGNORE
                         10 => 2449, # LOGOUT
                         11 => 904, # WRENCH
                         12 => 147, # EMOTE
                         13 => 962 }.freeze # MUSIC

  # Acceptable read types for database.
  READ_TYPES = %i[OFFSET NEGATIVE_OFFSET POST_NEGATIVE_OFFSET PRE_NEGATIVE_OFFSET
                  INVERTED NEGATIVE].freeze
  BYTE_TYPES = %i[A a C c S s STD std].freeze

  ## 317
  MESSAGE_SIZES = { 0 => 0, 1 => 0, 2 => 0, 3 => 1, 4 => -1, 5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0, 10 => 0,
                  11 => 0, 12 => 0, 13 => 0, 14 => 8, 15 => 0, 16 => 6, 17 => 2, 18 => 2, 19 => 0, 20 => 0,
                  21 => 2, 22 => 0, 23 => 6, 24 => 0, 25 => 12, 26 => 0, 27 => 0, 28 => 0, 29 => 0, 30 => 0,
                  31 => 0, 32 => 0, 33 => 0, 34 => 0, 35 => 8, 36 => 4, 37 => 0, 38 => 0, 39 => 2, 40 => 2,
                  41 => 6, 42 => 0, 43 => 6, 44 => 0, 45 => -1, 46 => 0, 47 => 0, 48 => 0, 49 => 0, 50 => 0,
                  51 => 0, 52 => 0, 53 => 12, 54 => 0, 55 => 0, 56 => 0, 57 => 8, 58 => 0, 59 => 0, 60 => 0,
                  61 => 8, 62 => 0, 63 => 0, 64 => 0, 65 => 0, 66 => 0, 67 => 0, 68 => 0, 69 => 0, 70 => 6,
                  71 => 0, 72 => 2, 73 => 2, 74 => 8, 75 => 6, 76 => 0, 77 => -1, 78 => 0, 79 => 6, 80 => 0,
                  81 => 0, 82 => 0, 83 => 0, 84 => 0, 85 => 1, 86 => 4, 87 => 6, 88 => 0, 89 => 0, 90 => 0,
                  91 => 0, 92 => 0, 93 => 0, 94 => 0, 95 => 3, 96 => 0, 97 => 0, 98 => -1, 99 => 0, 100 => 0,
                  101 => 13, 102 => 0, 103 => -1, 104 => 0, 105 => 0, 106 => 0, 107 => 0, 108 => 0, 109 => 0, 110 => 0,
                  111 => 0, 112 => 0, 113 => 0, 114 => 0, 115 => 0, 116 => 0, 117 => 6, 118 => 0, 119 => 0, 120 => 1,
                  121 => 0, 122 => 6, 123 => 0, 124 => 0, 125 => 0, 126 => -1, 127 => 0, 128 => 2, 129 => 6, 130 => 0,
                  131 => 4, 132 => 6, 133 => 8, 134 => 0, 135 => 6, 136 => 0, 137 => 0, 138 => 0, 139 => 2, 140 => 0,
                  141 => 0, 142 => 0, 143 => 0, 144 => 0, 145 => 6, 146 => 0, 147 => 0, 148 => 0, 149 => 0, 150 => 0,
                  151 => 0, 152 => 1, 153 => 2, 154 => 0, 155 => 2, 156 => 6, 157 => 0, 158 => 0, 159 => 0, 160 => 0,
                  161 => 0, 162 => 0, 163 => 0, 164 => -1, 165 => -1, 166 => 0, 167 => 0, 168 => 0, 169 => 0, 170 => 0,
                  171 => 0, 172 => 0, 173 => 0, 174 => 0, 175 => 0, 176 => 0, 177 => 0, 178 => 0, 179 => 0, 180 => 0,
                  181 => 8, 182 => 0, 183 => 3, 184 => 0, 185 => 2, 186 => 0, 187 => 0, 188 => 8, 189 => 1, 190 => 0,
                  191 => 0, 192 => 12, 193 => 0, 194 => 0, 195 => 0, 196 => 0, 197 => 0, 198 => 0, 199 => 0, 200 => 2,
                  201 => 0, 202 => 0, 203 => 0, 204 => 0, 205 => 0, 206 => 0, 207 => 0, 208 => 4, 209 => 0, 210 => 4,
                  211 => 0, 212 => 0, 213 => 0, 214 => 7, 215 => 8, 216 => 0, 217 => 0, 218 => 10, 219 => 0, 220 => 0,
                  221 => 0, 222 => 0, 223 => 0, 224 => 0, 225 => 0, 226 => -1, 227 => 0, 228 => 6, 229 => 0, 230 => 1,
                  231 => 0, 232 => 0, 233 => 0, 234 => 6, 235 => 0, 236 => 6, 237 => 8, 238 => 1, 239 => 0, 240 => 0,
                  241 => 4, 242 => 0, 243 => 0, 244 => 0, 245 => 0, 246 => -1, 247 => 0, 248 => -1, 249 => 4, 250 => 0,
                  251 => 0, 252 => 6, 253 => 6, 254 => 0, 255 => 0, 256 => 0 }.freeze

=begin
  # 377_MESSAGE_SIZES = { 0 => 0, 1 => 12, 2 => 0, 3 => 6, 4 => 6, 5 => 0, 6 => 0, 7 => 0, 8 => 2, 9 => 0, 10 => 0,
                  11 => 0, 12 => 0, 13 => 2, 14 => 0, 15 => 0, 16 => 0, 17 => 0, 18 => 0, 19 => 4, 20 => 0,
                  21 => 0, 22 => 2, 23 => 0, 24 => 6, 25 => 0, 26 => 0, 27 => 0, 28 => -1, 29 => 0, 30 => 0,
                  31 => 4, 32 => 0, 33 => 0, 34 => 0, 35 => 0, 36 => 8, 37 => 0, 38 => 0, 39 => 0, 40 => 0,
                  41 => 0, 42 => 2, 43 => 0, 44 => 0, 45 => 2, 46 => 0, 47 => 0, 48 => 0, 49 => -1, 50 => 6,
                  51 => 0, 52 => 0, 53 => 0, 54 => 6, 55 => 6, 56 => -1, 57 => 8, 58 => 0, 59 => 0, 60 => 0,
                  61 => 0, 62 => 0, 63 => 0, 64 => 0, 65 => 0, 66 => 0, 67 => 2, 68 => 0, 69 => 0, 70 => 0,
                  71 => 6, 72 => 0, 73 => 0, 74 => 0, 75 => 4, 76 => 0, 77 => 6, 78 => 4, 79 => 2, 80 => 2,
                  81 => 0, 82 => 0, 83 => 8, 84 => 0, 85 => 0, 86 => 0, 87 => 0, 88 => 0, 89 => 0, 90 => 0,
                  91 => 6, 92 => 0, 93 => 0, 94 => 0, 95 => 4, 96 => 0, 97 => 0, 98 => 0, 99 => 0, 100 => 6,
                  101 => 0, 102 => 0, 103 => 0, 104 => 4, 105 => 0, 106 => 0, 107 => 0, 108 => 0, 109 => 0, 110 => 0,
                  111 => 0, 112 => 2, 113 => 0, 114 => 0, 115 => 0, 116 => 2, 117 => 0, 118 => 0, 119 => 1, 120 => 8,
                  121 => 0, 122 => 0, 123 => 7, 124 => 0, 125 => 0, 126 => 1, 127 => 0, 128 => 0, 129 => 0, 130 => 0,
                  131 => 0, 132 => 0, 133 => 0, 134 => 0, 135 => 0, 136 => 6, 137 => 0, 138 => 0, 139 => 0, 140 => 4,
                  141 => 8, 142 => 0, 143 => 8, 144 => 0, 145 => 0, 146 => 0, 147 => 0, 148 => 0, 149 => 0, 150 => 0,
                  151 => 0, 152 => 12, 153 => 0, 154 => 0, 155 => 0, 156 => 0, 157 => 4, 158 => 6, 159 => 0, 160 => 8,
                  161 => 6, 162 => 0, 163 => 13, 164 => 0, 165 => 1, 166 => 0, 167 => 0, 168 => 0, 169 => 0, 170 => 0,
                  171 => -1, 172 => 0, 173 => 3, 174 => 0, 175 => 0, 176 => 3, 177 => 6, 178 => 0, 179 => 0, 180 => 0,
                  181 => 6, 182 => 0, 183 => 0, 184 => 10, 185 => 0, 186 => 0, 187 => 1, 188 => 0, 189 => 0, 190 => 0,
                  191 => 0, 192 => 0, 193 => 0, 194 => 2, 195 => 0, 196 => 0, 197 => 4, 198 => 0, 199 => 0, 200 => 0,
                  201 => 0, 202 => 0, 203 => 6, 204 => 0, 205 => 0, 206 => 8, 207 => 0, 208 => 0, 209 => 0, 210 => 8,
                  211 => 12, 212 => 0, 213 => -1, 214 => 0, 215 => 0, 216 => 0, 217 => 8, 218 => 0, 219 => 0, 220 => 0,
                  221 => 0, 222 => 3, 223 => 0, 224 => 0, 225 => 0, 226 => 2, 227 => 9, 228 => 6, 229 => 0, 230 => 6,
                  231 => 6, 232 => 0, 233 => 2, 234 => 0, 235 => 0, 236 => 0, 237 => 0, 238 => 0, 239 => 0, 240 => 0,
                  241 => 6, 242 => 0, 243 => 0, 244 => -1, 245 => 2, 246 => 0, 247 => -1, 248 => 0, 249 => 0, 250 => 0,
                  251 => 0, 252 => 0, 253 => 0, 254 => 0, 255 => 0 }.freeze
=end

  # Acceptable byte orders in which multi-byte values can be read.
  BYTE_ORDERS = %i[BIG MIDDLE INVERSE_MIDDLE LITTLE].freeze

  # The size of one byte
  BYTE_SIZE = 8

  # Valid readable/writable types
  RW_TYPES = {
    bit: %i[bit BIT],
    byte: %i[byte b Byte BYTE B],
    short: %i[short s SHORT S],
    medium: %i[tribyte tri-byte medium med m tb int24 MED MEDIUM M TRIBYTE TRI-BYTE INT24],
    int: %i[int integer i INT INTEGER I],
    long: %i[long l LONG g],
    smart: %i[smart SMART],
    string: %i[str string STRING STR]
  }.freeze

  # Valid byte mutations
  BYTE_MUTATIONS = {
    std: %i[STD STANDARD s NONE std],
    add: %i[A Add a add ADD],
    sub: %i[S Sub Subtract s sub subtract SUB SUBTRACT],
    neg: %i[C c N n Negate Neg neg negate NEG NEGATE]
  }.freeze

  # Bit masks for bit packing
  BIT_MASK_OUT = (0...32).collect { |i| (1 << i) - 1 }
end