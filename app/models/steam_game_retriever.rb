require 'nokogiri'
require 'open-uri'

class SteamGameRetriever

	def get_steam_id(steam_username)
		games_xml = Nokogiri::XML open("http://steamcommunity.com/id/#{steam_username}/games?tab=all&xml=1")
		games_xml.xpath('//gamesList/steamID64').text
	end

	def load_games_for_user(steam_user)
		games_xml = Nokogiri::XML open("http://steamcommunity.com/id/#{steam_user.steam_name}/games?tab=all&xml=1")

		games_xml.xpath('//gamesList/games/game').each do |game_xml|
			game_from_xml = SteamGame::from_xml game_xml.to_s

			existing_steam_game = SteamGame.where(:app_id => game_from_xml.app_id).first

			if existing_steam_game.nil?
				existing_steam_game = game_from_xml
			else
				existing_steam_game.update_attributes({
					:name => game_from_xml.name,
					:image_path => game_from_xml.image_path
				})
			end

			existing_steam_game.save!

			if SteamUserGame.where('steam_id = ? and steam_app_id = ?', steam_user.steam_id, existing_steam_game.app_id).first.nil?
				SteamUserGame.create! :steam_id => steam_user.steam_id, :steam_app_id => existing_steam_game.app_id
			end
		end
	end

	def get_recently_played_games(steam_user)
		api_key = ENV['STEAM_API_KEY']
		games_xml = Nokogiri::XML open("http://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=#{api_key}&steamid=#{steam_user.steam_id}&format=xml")
		games = []

		games_xml.xpath('//response/games/message').each do |message|
			message_hash = Hash.from_xml message.to_s
			games.push SteamGame.find_by_app_id(message_hash['message']['appid'])
		end

		games
	end
end