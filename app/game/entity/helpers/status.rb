module RuneRb::Game::Entity::Helpers::Status

	def load_status
		@status = @profile.status
		@session.write_message(:MembersAndIndexMessage, members: @status.members, player_idx: @index)
		@session.write_message(:UpdateItemsMessage, data: @inventory[:container].data, size: 28)
		@session.write_message(:SystemTextMessage, message: 'Check the repository for updates! https://gitlab.com/Sickday/rune.rb')
		@session.write_message(:SystemTextMessage, message: "VERSION: #{RuneRb::GLOBAL[:VERSION]}")
		update(:sidebars)
	end

	def post_status
		@status.post_session(ip: @session.ip, duration: @session.up_time, date: @session.start[:stamp])
	end
end