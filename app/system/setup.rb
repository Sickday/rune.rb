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

module RuneRb::System::Setup
  extend self

  def load_mob_data(settings)
    case settings[:STORAGE_TYPE]
    when :sqlite
      settings[:MOB_SPAWNS] = settings[:CONNECTION][:mob_spawns]
      settings[:MOB_STATS] = settings[:CONNECTION][:mob_stats]
      settings[:MOB_ANIMATIONS] = settings[:CONNECTION][:mob_animations]
      settings[:MOB_DEFINITIONS] = settings[:CONNECTION][:mob_definitions]
    when :postgres
    else "Invalid storage mode! #{settings[:RRB_STORAGE_TYPE]}"
    end
  rescue StandardError => e
    settings[:LOG].error "An error occurred while loading game database!"
    settings[:LOG].error e
    settings[:LOG].error e.backtrace&.join("\n")
  end

  def load_player_data(settings)
    case settings[:STORAGE_TYPE]
    when :sqlite
      settings[:PLAYER_APPEARANCES] = settings[:CONNECTION][:player_appearance]
      settings[:PLAYER_PROFILES] = settings[:CONNECTION][:player_profiles]
      settings[:PLAYER_SETTINGS] = settings[:CONNECTION][:player_settings]
      settings[:PLAYER_STATS] = settings[:CONNECTION][:player_stats]
      settings[:PLAYER_STATUS] = settings[:CONNECTION][:player_status]
    when :postgres
    else "Invalid storage mode! #{settings[:RRB_STORAGE_TYPE]}"
    end
  rescue StandardError => e
    settings[:LOG].error "An error occurred while loading game database!"
    settings[:LOG].error e
    settings[:LOG].error e.backtrace&.join("\n")
  end

  def load_item_data(settings)
    case settings[:STORAGE_TYPE]
    when :sqlite
      settings[:ITEM_SPAWNS] = settings[:CONNECTION][:item_spawns]
      settings[:ITEM_DEFINITIONS] = settings[:CONNECTION][:item_definitions]
      settings[:ITEM_EQUIPMENT] = settings[:CONNECTION][:item_equipment]
    when :postgres
    else "Invalid storage mode! #{settings[:RRB_STORAGE_TYPE]}"
    end
  rescue StandardError => e
    settings[:LOG].error "An error occurred while loading game database!"
    settings[:LOG].error e
    settings[:LOG].error e.backtrace&.join("\n")
  end

  def load_game_data(settings)
    case settings[:STORAGE_TYPE]
    when :sqlite
      settings[:GAME_BANNED_NAMES] = settings[:CONNECTION][:game_banned_names]
      settings[:GAME_SNAPSHOTS] = settings[:CONNECTION][:game_snapshots]
      settings[:GAME_LOCATIONS] = settings[:CONNECTION][:game_locations]
    when :postgres
    else "Invalid storage mode! #{settings[:RRB_STORAGE_TYPE]}"
    end
  rescue StandardError => e
    settings[:LOG].error "An error occurred while loading game database!"
    settings[:LOG].error e
    settings[:LOG].error e.backtrace&.join("\n")
  end

  def load_logger(settings)
    settings[:VERSION] = `rake runerb:get_version`.chomp.gsub!("\"", '')
    FileUtils.mkdir_p("#{FileUtils.pwd}/assets/log")
    settings[:LOG_FILE_PATH] = "#{FileUtils.pwd}/assets/log/rune_rb-#{Time.now.strftime('%Y-%m-%d').chomp}.log".freeze
    settings[:LOG_FILE] = Logger.new(settings[:LOG_FILE_PATH], progname: "rune.rb-#{settings[:VERSION]}")
    settings[:LOG] = Logger.new(STDOUT)
    settings[:COLOR] = Pastel.new
    settings[:LOG].formatter = proc do |sev, date, _prog, msg|
      "#{settings[:COLOR].green.bold("[#{date.strftime('%H:%M')}]")}|#{settings[:COLOR].blue("[#{sev}]")} : #{msg}\n"
    end
  end

  def load_global_data(settings)
    Oj.load(File.read('assets/config/rune.rb.json')).each do |key, value|
      settings[key.upcase.to_sym] = value
    end
    settings[:STORAGE_TYPE] = settings[:STORAGE_TYPE].to_sym
    settings[:CONNECTION] = case settings[:STORAGE_TYPE]
                            when :sqlite then Sequel.sqlite('assets/sample.db3')
                            when :postgres
                            else Sequel.sqlite('assets/sample.db3')
                            end
  end
end
