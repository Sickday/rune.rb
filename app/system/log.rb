module RuneRb::System::Log
  # Gets this class' name.
  def class_name
    self.class.name.split('::').last.to_sym
  end

  ##
  # Log info lines
  # @param lines [Array] lines of text that are passed to the logger.
  def log(*lines)
    lines.each do |line|
      RuneRb::GLOBAL[:LOG_FILE].info(RuneRb::GLOBAL[:COLOR].strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::GLOBAL[:LOG].info(RuneRb::GLOBAL[:COLOR].white("[#{class_name}] -> #{line}"))
    end
    nil
  end

  ##
  # Log warning lines
  # @param lines [Array] lines of text that are passed to the logger.
  def log!(*lines)
    lines.each do |line|
      RuneRb::GLOBAL[:LOG_FILE].warn(RuneRb::GLOBAL[:COLOR].strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::GLOBAL[:LOG].warn(RuneRb::GLOBAL[:COLOR].yellow("[#{class_name}] -> #{line}"))
    end
    nil
  end

  alias debug log!

  ##
  # Log error lines
  # @param lines [Array] lines of text that are passed to the logger.
  def err(*lines)
    lines.each do |line|
      RuneRb::GLOBAL[:LOG_FILE].error(RuneRb::GLOBAL[:COLOR].strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::GLOBAL[:LOG].error(RuneRb::GLOBAL[:COLOR].magenta.bold("[#{class_name}] ~> #{line}"))
    end
    nil
  end

  ##
  # Log fatal lines
  # @param lines [Array] lines of text that are passed to the logger.
  def err!(*lines)
    lines.each do |line|
      RuneRb::GLOBAL[:LOG_FILE].fatal(RuneRb::GLOBAL[:COLOR].strip("[#{Time.now.strftime('[%H:%M')}] #{line}"))
      RuneRb::GLOBAL[:LOG].error(RuneRb::GLOBAL[:COLOR].red.bold("[#{class_name}] ~> #{line}"))
    end
    nil
  end

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