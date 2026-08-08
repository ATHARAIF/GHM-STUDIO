extends Node

signal time_advanced(year: int, season: int, turn_in_season: int, turn_in_year: int)
signal year_changed(year: int)
signal season_changed(season: int)

enum Season { SPRING, SUMMER, FALL, WINTER }

var year: int = 2025
var season: int = Season.SPRING
var turn_in_season: int = 1
var turn_in_year: int = 1

func advance_turn() -> void:
	turn_in_year += 1
	if turn_in_year > 20:
		turn_in_year = 1
		year += 1
		year_changed.emit(year)
		
	turn_in_season = ((turn_in_year - 1) % 5) + 1
	
	@warning_ignore("integer_division")
	var new_season = int((turn_in_year - 1) / 5) % 4
	if new_season != season:
		season = new_season
		season_changed.emit(season)
		
	time_advanced.emit(year, season, turn_in_season, turn_in_year)
