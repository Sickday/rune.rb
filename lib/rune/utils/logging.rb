module RuneRb::Utils::Logging

  # @!attribute [r] COLORS
  # @return [Pastel] provides String coloring functions.
  COLORS = RuneRb::LOGGER.colors

  # @!attribute [r] LOG_FILE
  # @return [Logger] logger that writes to a file.
  LOG_FILE = RuneRb::LOGGER.file

  # @!attribute [r] STDOUT
  # @return [Logger] logger that writes to {$stdout}.
  LOG_STDOUT = RuneRb::LOGGER.stdout

  # Gets this class' name.
  def class_name
    self.class.name.split('::').last.to_sym
  end

  # Log info lines
  # @param lines [Array] lines of text that are passed to the logger.
  # @param app_name [String] the name of the application.
  def log(*lines, app_name: @label || 'rune.rb')
    lines.each do |line|
      LOG_STDOUT.info(COLORS.white("[#{class_name}] -> #{line}"))
      LOG_FILE.info(app_name) { "[#{Time.now.strftime('%H:%M')}] #{COLORS.strip(line)}" }
    end
    nil
  end

  alias info log

  # Log warning lines
  # @param lines [Array] lines of text that are passed to the RuneRb::GLOBAL[:LOGGER].
  # @param app_name [String] the name of the application.
  def log!(*lines, app_name: @label || 'rune.rb')
    lines.each do |line|
      LOG_STDOUT.warn(COLORS.yellow("[#{class_name}] -> #{line}"))
      LOG_FILE.warn(app_name) { "[#{Time.now.strftime('%H:%M')}] #{COLORS.strip(line)}" }
    end
    nil
  end

  alias debug log!
  alias warn log!

  # Log error lines
  # @param lines [Array] lines of text that are passed to the RuneRb::GLOBAL[:LOGGER].
  # @param app_name [String] the name of the application.
  def err(*lines, app_name: @label || 'rune.rb')
    lines.each do |line|
      LOG_STDOUT.error(COLORS.magenta.bold("[#{class_name}] ~> #{line}"))
      LOG_FILE.error(app_name) { "[#{Time.now.strftime('%H:%M')}] #{COLORS.strip(line)}" }
    end
    nil
  end

  alias error err

  # Log fatal lines
  # @param lines [Array] lines of text that are passed to the RuneRb::GLOBAL[:LOGGER].
  # @param app_name [String] the name of the application.
  def err!(*lines, app_name: @label || 'rune.rb')
    lines.each do |line|
      LOG_STDOUT.error(COLORS.red.bold("[#{class_name}] ~> #{line}"))
      LOG_FILE.fatal(app_name) { "[#{Time.now.strftime('%H:%M')}] #{COLORS.strip(line)}" }
    end
    nil
  end

  alias fatal err!

  # Returns the file name as a symbol.
  # @param string [String] The path to the file.
  def symbolize_file(string)
    File.basename(string, '*.rb').to_sym
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
