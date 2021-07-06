module RuneRb::Database::Connection
	extend self

	def setup(configuration = {})
		begin
			if configuration.has_key?(:RAW)
				raise 'Unable to locate GLOBAL mapping!' unless configuration[:RAW].has_key?('GLOBAL')

				configuration[:STORAGE_TYPE] = configuration[:RAW]['GLOBAL']['STORAGE_TYPE'].to_sym
				puts "weens"
				configuration[:CONNECTION] = case configuration[:STORAGE_TYPE]
					                             when :sqlite then configuration[:CONNECTION] = Sequel.connect('sqlite://assets/sample.db3', pragma: :foreign_keys,
					                                                                                          loggers: RuneRb::GLOBAL[:RAW]['GLOBAL']['DATABASE']['DEBUG'] ? RuneRb::GLOBAL[:LOG] : nil)
					                             when :postgres then configuration[:CONNECTION] = {
						                             PROFILE_DATA: Sequel.postgres(configuration[:RAW]['DATABASE']['POSTGRES']['PROFILE_DATA'],
						                                                           user: configuration[:RAW]['DATABASE']['POSTGRES']['USER'],
						                                                           password: configuration[:RAW]['DATABASE']['POSTGRES']['PASS'],
						                                                           host: configuration[:RAW]['DATABASE']['POSTGRES']['HOST'],
						                                                           port: configuration[:RAW]['DATABASE']['POSTGRES']['PORT'],
						                                                           loggers: RuneRb::GLOBAL[:RAW]['GLOBAL']['DATABASE']['DEBUG'] ? RuneRb::GLOBAL[:LOG] : nil),
						                             GAME_DATA: Sequel.postgres(configuration[:RAW]['DATABASE']['POSTGRES']['GAME_DATA'],
						                                                        user: configuration[:RAW]['DATABASE']['POSTGRES']['USER'],
						                                                        password: configuration[:RAW]['DATABASE']['POSTGRES']['PASS'],
						                                                        host: configuration[:RAW]['DATABASE']['POSTGRES']['HOST'],
						                                                        port: configuration[:RAW]['DATABASE']['POSTGRES']['PORT'],
						                                                        loggers: RuneRb::GLOBAL[:RAW]['GLOBAL']['DATABASE']['DEBUG'] ? RuneRb::GLOBAL[:LOG] : nil),
						                             DEFINITION_DATA: Sequel.postgres(configuration[:RAW]['DATABASE']['POSTGRES']['DEFINITION_DATA'],
						                                                              user: configuration[:RAW]['DATABASE']['POSTGRES']['USER'],
						                                                              password: configuration[:RAW]['DATABASE']['POSTGRES']['PASS'],
						                                                              host: configuration[:RAW]['DATABASE']['POSTGRES']['HOST'],
						                                                              port: configuration[:RAW]['DATABASE']['POSTGRES']['PORT'],
						                                                              loggers: RuneRb::GLOBAL[:RAW]['GLOBAL']['DATABASE']['DEBUG'] ? RuneRb::GLOBAL[:LOG] : nil)
					                             }
				                             end
			else
				configuration[:STORAGE_TYPE] = :sqlite
				configuration[:CONNECTION] = Sequel.sqlite('assets/sample.db3', pragma: :foreign_keys)
				## TODO: What if we offer the option to fetch a blank via somethin like open-uri or syscommands
			end
		rescue StandardError => e
			puts 'An error occurred while constructing database connection(s)!'
			puts e
			puts e.backtrace.join("\n")
		end
	end

	def setup_player_datasets(destination = {}, configuration)
		case configuration[:STORAGE_TYPE]
			when :sqlite
				destination[:PLAYER_APPEARANCES] = configuration[:CONNECTION][:player_appearance]
				destination[:PLAYER_PROFILES] = configuration[:CONNECTION][:player_profiles]
				destination[:PLAYER_LOCATIONS] = configuration[:CONNECTION][:player_locations]
				destination[:PLAYER_SETTINGS] = configuration[:CONNECTION][:player_settings]
				destination[:PLAYER_STATS] = configuration[:CONNECTION][:player_stats]
				destination[:PLAYER_STATUS] = configuration[:CONNECTION][:player_status]
			when :postgres
				destination[:PLAYER_APPEARANCES] = configuration[:CONNECTION][:PROFILE_DATA][:player_appearance]
				destination[:PLAYER_PROFILES] = configuration[:CONNECTION][:PROFILE_DATA][:player_profiles]
				destination[:PLAYER_LOCATIONS] = configuration[:CONNECTION][:PROFILE_DATA][:player_locations]
				destination[:PLAYER_SETTINGS] = configuration[:CONNECTION][:PROFILE_DATA][:player_settings]
				destination[:PLAYER_STATS] = configuration[:CONNECTION][:PROFILE_DATA][:player_stats]
				destination[:PLAYER_STATUS] = configuration[:CONNECTION][:PROFILE_DATA][:player_status]
			else raise "Unrecognized configuration type! #{configuration[:STORAGE_TYPE]}"
		end
	end

	def setup_item_datasets(destination = {}, configuration)
		case configuration[:STORAGE_TYPE]
			when :sqlite
				destination[:ITEM_SPAWNS] = configuration[:CONNECTION][:item_spawns]
				destination[:ITEM_DEFINITIONS] = configuration[:CONNECTION][:item_definitions]
				destination[:ITEM_EQUIPMENT] = configuration[:CONNECTION][:item_equipment]
			when :postgres
				destination[:ITEM_SPAWNS] = configuration[:CONNECTION][:GAME_DATA][:item_spawns]
				destination[:ITEM_DEFINITIONS] = configuration[:CONNECTION][:DEFINITION_DATA][:item_definitions]
				destination[:ITEM_EQUIPMENT] = configuration[:CONNECTION][:DEFINITION_DATA][:item_equipment]
			else raise "Unrecognized configuration type! #{configuration[:STORAGE_TYPE]}"
		end
	end

	def setup_mob_datasets(destination = {}, configuration)
		case configuration[:STORAGE_TYPE]
			when :sqlite
				destination[:MOB_SPAWNS] = configuration[:CONNECTION][:mob_spawns]
				destination[:MOB_STATS] = configuration[:CONNECTION][:mob_stats]
				destination[:MOB_ANIMATIONS] = configuration[:CONNECTION][:mob_animations]
				destination[:MOB_DEFINITIONS] = configuration[:CONNECTION][:mob_definitions]
			when :postgres
				destination[:MOB_SPAWNS] = configuration[:CONNECTION][:GAME_DATA][:mob_spawns]
				destination[:MOB_STATS] = configuration[:CONNECTION][:GAME_DATA][:mob_stats]
				destination[:MOB_ANIMATIONS] = configuration[:CONNECTION][:DEFINITION_DATA][:mob_animations]
				destination[:MOB_DEFINITIONS] = configuration[:CONNECTION][:DEFINITION_DATA][:mob_definitions]
			else raise "Unrecognized configuration type! #{configuration[:STORAGE_TYPE]}"
		end
	end

	def setup_game_datasets(destination = {}, configuration)
		case configuration[:STORAGE_TYPE]
			when :sqlite
				destination[:GAME_BANNED_NAMES] = configuration[:CONNECTION][:game_banned_names]
				destination[:GAME_SNAPSHOTS] = configuration[:CONNECTION][:game_snapshots]
			when :postgres
				destination[:GAME_BANNED_NAMES] = configuration[:CONNECTION][:GAME_DATA][:banned_names]
				destination[:GAME_SNAPSHOTS] = configuration[:CONNECTION][:GAME_DATA][:snapshots]
			else raise "Unrecognized configuration type! #{configuration[:STORAGE_TYPE]}"
		end
	end

	def shutdown(connection)
		connection&.disconnect
	rescue StandardError => e
		puts 'An error occurred while closing database connection!'
		puts e
		puts e.backtrace.join("\n")
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