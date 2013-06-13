Movies::Application.routes.draw do

	devise_for :users

	get '/projects' => 'projects#index'

	get '/movies' => 'movies#index'
	get '/movies/:movie_id/movie_performances' => 'movies#performances'

	get '/leaderboard' => 'leaderboard#index'
	get '/leaderboard/individuals' => 'leaderboard#individuals'
	get '/leaderboard/something' => 'leaderboard#something'

	get '/tvshows/series/:series_id' => 'tvshows#series'
	get '/tvshows/upcoming' => 'tvshows#upcoming'
	get '/tvshows/' => 'tvshows#index'

	get '/calendar/events' => 'calendar#events'
	get '/calendar' => 'calendar#index'

	root :to => 'application#frontpage'
end
