extends Control

signal menu_pressed
signal setting_pressed
signal journal_pressed

@onready var label_calendar = $MarginContainer/hbox/left/calendar/label
@onready var label_money = $MarginContainer/hbox/left/money/label

@onready var btn_menu = $MarginContainer/hbox/right/menu
@onready var btn_setting = $MarginContainer/hbox/right/setting
@onready var btn_journal = $MarginContainer/hbox/right/journal

func _ready() -> void:
	# Connect to global signals
	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.budget_changed.connect(_on_budget_changed)
	
	# Connect internal buttons to emit signals upwards
	if btn_menu:
		btn_menu.pressed.connect(func(): menu_pressed.emit())
	if btn_setting:
		btn_setting.pressed.connect(func(): setting_pressed.emit())
	if btn_journal:
		btn_journal.pressed.connect(func(): journal_pressed.emit())
		
	# Initial UI update
	_update_initial_state()

func _update_initial_state() -> void:
	# Ensure the UI reflects the current state immediately on load
	_on_turn_changed(TimeManager.turn_in_year, TimeManager.season, TimeManager.year)
	_on_budget_changed(StageManager.budget)

func _on_turn_changed(turn_in_year: int, season: int, year: int) -> void:
	var season_name = ""
	match season:
		TimeManager.Season.SPRING: season_name = "Spring"
		TimeManager.Season.SUMMER: season_name = "Summer"
		TimeManager.Season.FALL: season_name = "Fall"
		TimeManager.Season.WINTER: season_name = "Winter"
		
	if label_calendar:
		label_calendar.text = "%d %s %d" % [TimeManager.turn_in_season, season_name, year]

func _on_budget_changed(budget: int) -> void:
	if label_money:
		label_money.text = "%d" % budget
