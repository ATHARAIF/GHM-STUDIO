extends Control

signal menu_pressed
signal setting_pressed
signal journal_pressed

@onready var label_calendar = $status/calendar
@onready var label_money = $status/money/balance

@onready var btn_menu = $utility/menu
@onready var btn_setting = $utility/setting
@onready var btn_journal = $utility/journal

func _ready() -> void:
	# Connect to global signals
	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.budget_changed.connect(_on_budget_changed)
	
	# Connect internal buttons to emit signals upwards
	if btn_menu:
		btn_menu.pressed.connect(_on_menu_pressed)
	if btn_setting:
		btn_setting.pressed.connect(_on_setting_pressed)
	if btn_journal:
		btn_journal.pressed.connect(_on_journal_pressed)
		
	# Pastikan tombol close sembunyi saat mulai
	if has_node("utility/close"):
		$utility/close.hide()
		$utility/close.pressed.connect(_close_popup)
		
	# Initial UI update
	_update_initial_state()

const MENU_PANEL = preload("res://scenes/ui/menu/menu_panel.tscn")
var active_menu: Node = null
var active_popup_button: Button = null

func _on_menu_pressed() -> void:
	if active_menu != null: _close_popup()
	else: _open_popup(MENU_PANEL, btn_menu)

func _on_journal_pressed() -> void:
	print("Tombol Journal ditekan! (UI belum dibuat)")
	# Nanti ganti dengan: _open_popup(JOURNAL_PANEL, btn_journal)

func _on_setting_pressed() -> void:
	print("Tombol Setting ditekan! (UI belum dibuat)")
	# Nanti ganti dengan: _open_popup(SETTING_PANEL, btn_setting)

func _open_popup(popup_scene: PackedScene, source_btn: Button) -> void:
	active_menu = popup_scene.instantiate()
	get_tree().current_scene.add_child(active_menu)
	
	active_popup_button = source_btn
	
	if has_node("utility/close"):
		var btn_close = $utility/close
		var target_index = source_btn.get_index()
		
		# Sembunyikan tombol asli, munculkan tombol close
		source_btn.hide()
		btn_close.show()
		
		# Pindahkan tombol close ke posisi tombol asli di dalam HBoxContainer!
		$utility.move_child(btn_close, target_index)

func _close_popup() -> void:
	if active_menu != null and is_instance_valid(active_menu):
		active_menu.queue_free()
		active_menu = null
		
	if has_node("utility/close"):
		$utility/close.hide()
		
	if active_popup_button != null:
		active_popup_button.show()
		active_popup_button = null

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
