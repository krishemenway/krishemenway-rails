#global ko
class GamesViewModel
	constructor: () ->
		self = this
		self.isQueryingServer = ko.observable(false)
		tryOneMoreTime = false
		last_searched_query = ""

		self.recently_played = ko.observableArray()
		self.tags = ko.observableArray()

		self.search_results = ko.observableArray()
		self.search_query = ko.observable()
		self.selected_game = ko.observable()

		clear_search = () ->
			self.search_results([])
			self.search_query("")
			last_searched_query = ""

		create_tags_from_server = (tags_json)  ->
			(new TagViewModel(tag) for tag in tags_json)

		create_games_from_server = (games_json) ->
			(new GameViewModel(game) for game in games_json)

		load_search_results = (games_from_server) ->
			self.isQueryingServer(false)

			if tryOneMoreTime
				tryOneMoreTime = false
				self.try_to_search()
			else
				self.selected_game(null)
				self.search_results(create_games_from_server(games_from_server))

		can_search = () ->
			self.search_query().length >= 2 and last_searched_query != self.search_query()

		self.open_profile = (game) ->
			self.selected_game(game)
			self.selected_game().initialize_extras()
			clear_search()

		self.search_for_tag = (tag) ->
			self.search_query("tag:" + tag.name)
			self.try_to_search()

		self.try_to_search = () ->
			unless can_search()
				return

			if self.isQueryingServer()
				tryOneMoreTime = true
			else
				self.isQueryingServer(true)
				$.getJSON "/games/search/game", { query: self.search_query() }, load_search_results
				last_searched_query = self.search_query()

		self.init = (recently_played_games_from_server, initial_search_results_from_server, tags_from_server) ->
			self.recently_played(create_games_from_server(recently_played_games_from_server))
			self.search_results(create_games_from_server(initial_search_results_from_server))
			self.tags(create_tags_from_server(tags_from_server))

		return self

class GameViewModel
	constructor: (game_json) ->
		self = this

		self.name = game_json.name
		self.app_id = game_json.app_id
		self.image_path = game_json.image_path
		self.run_url = game_json.run_url

		self.tags = ko.observableArray()
		self.articles = ko.observableArray()

		self.new_tag_name = ko.observable()
		self.adding_tag = ko.observable(false)

		self.is_loading_news = ko.observable(false)

		handle_successful_add = (response) ->
			self.tags.push(new TagViewModel(JSON.parse(response)))
			self.tags(self.tags())

		load_tags = (response) ->
			tags = (new TagViewModel(tag) for tag in response)
			self.tags(tags)

		load_news = (response) ->
			self.articles(response)
			self.is_loading_news(false)

		fetch_and_load_tags = () ->
			$.getJSON '/games/game/tags', {app_id: self.app_id}, load_tags

		fetch_and_load_news = () ->
			self.is_loading_news(true)
			$.getJSON '/games/game/news', {app_id: self.app_id}, load_news

		self.start_adding_tag = () ->
			self.adding_tag(true)

		self.initialize_extras = () ->
			fetch_and_load_tags()
			fetch_and_load_news()

		self.add_tag = () ->
			$.post '/games/game/tag_game', {app_id: self.app_id, tag_name: self.new_tag_name()}, handle_successful_add
			self.new_tag_name('')
			self.adding_tag(false)

		return self

class TagViewModel
	constructor: (tag_json) ->
		self = this

		self.name = tag_json.name
		self.examples = []

		for game in [tag_json.example_one, tag_json.example_two]
			self.examples.push(new GameViewModel(JSON.parse(game))) if game != "null"

		return self

window.GamesViewModel = GamesViewModel