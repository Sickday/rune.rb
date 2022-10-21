module RuneRb::Utils::Logging

  # Gets this class' name.
  def class_name
    self.class.name.split('::').last.to_sym
  end

  def condense(lines)
    lines.is_a?(Array) ? lines.join("\n") : lines
  end

  # Log info lines
  # @param lines [Array, String] lines of text that are passed to the logger.
  def log(lines, to_stdout: true, to_file: true)
    RuneRb::LOGGER.stdout.info(RuneRb::LOGGER.colors.white("[#{class_name}] -> #{condense(lines)}")) if to_stdout
    RuneRb::LOGGER.file.info("[#{class_name}] -> #{condense(lines)}") if to_file
    nil
  end

  alias info log

  # Log warning lines
  # @param lines [Array] lines of text that are passed to the RuneRb::GLOBAL[:LOGGER].
  def log!(*lines, to_stdout: true, to_file: true)
    RuneRb::LOGGER.stdout.warn(RuneRb::LOGGER.colors.white("[#{class_name}] -> #{condense(lines)}")) if to_stdout
    RuneRb::LOGGER.file.warn("[#{class_name}] -> #{condense(lines)}") if to_file
    nil
  end

  alias debug log!
  alias warn log!

  # Log error lines
  # @param lines [Array] lines of text that are passed to the RuneRb::GLOBAL[:LOGGER].
  def err(*lines, to_stdout: true, to_file: true)
    RuneRb::LOGGER.stdout.error(RuneRb::LOGGER.colors.white("[#{class_name}] -> #{condense(lines)}")) if to_stdout
    RuneRb::LOGGER.file.error("[#{class_name}] -> #{condense(lines)}") if to_file
    nil
  end

  alias error err

  # Log fatal lines
  # @param lines [Array] lines of text that are passed to the RuneRb::GLOBAL[:LOGGER].
  def err!(*lines, to_stdout: true, to_file: true)
    RuneRb::LOGGER.stdout.fatal(RuneRb::LOGGER.colors.white("[#{class_name}] -> #{condense(lines)}")) if to_stdout
    RuneRb::LOGGER.file.fatal("[#{class_name}] -> #{condense(lines)}") if to_file
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
