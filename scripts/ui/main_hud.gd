extends Control

@onready var btn_calendar = $main/header/HBoxContainer/calendar
@onready var btn_money = $main/header/HBoxContainer/money
@onready var btn_end_turn = $main/footer/Button

# Temporary Debug Stats
@onready var debug_panel = $main/PanelContainer/DebugStats
@onready var debug_body = $main/PanelContainer/DebugStats/Body
@onready var debug_acidity = $main/PanelContainer/DebugStats/Acidity
@onready var debug_sweetness = $main/PanelContainer/DebugStats/Sweetness
@onready var debug_aroma = $main/PanelContainer/DebugStats/Aroma
@onready var debug_flavor = $main/PanelContainer/DebugStats/Flavor
@onready var debug_moisture = $main/PanelContainer/DebugStats/Moisture
@onready var debug_defect = $main/PanelContainer/DebugStats/Defect
@onready var debug_yield = $main/PanelContainer/DebugStats/Yield

# Popup Buttons
@onready var btn_menu = $main/header/HBoxContainer2/menu
@onready var btn_setting = $main/header/HBoxContainer2/setting
@onready var btn_journal = $main/header/HBoxContainer2/journal

# Popup Layers
@onready var layer_menu_tabs = $menu_tabs
@onready var layer_coffee_log = $menu_coffee_log

func _ready() -> void:
	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.budget_changed.connect(_on_budget_changed)
	
	StageManager.stats_changed.connect(_on_stats_changed)
	StageManager.interaction_requested.connect(_on_stage_interaction_requested)
	
	if btn_end_turn:
		btn_end_turn.pressed.connect(_on_end_turn_pressed)
		
	if btn_menu:
		btn_menu.pressed.connect(func(): _toggle_popup(layer_menu_tabs))
	if btn_journal:
		btn_journal.pressed.connect(func(): _toggle_popup(layer_coffee_log))
		
	_update_all()

func _toggle_popup(layer: CanvasLayer) -> void:
	if layer:
		layer.visible = !layer.visible
		# Optional: Hide the other popup if one is opened
		if layer == layer_menu_tabs and layer_coffee_log:
			layer_coffee_log.visible = false
		elif layer == layer_coffee_log and layer_menu_tabs:
			layer_menu_tabs.visible = false

func _on_stage_interaction_requested(interaction_type: String, tile_data: Dictionary) -> void:
	if interaction_type == "DRY":
		if has_node("DryPopup"):
			get_node("DryPopup").show_popup(tile_data)
			if btn_end_turn: btn_end_turn.disabled = true
	elif interaction_type == "HARVEST":
		if has_node("HarvestResultPopup"):
			get_node("HarvestResultPopup").show_popup(tile_data)
			if btn_end_turn: btn_end_turn.disabled = true

func _update_all() -> void:
	_on_turn_changed(TimeManager.turn_in_year, TimeManager.season, TimeManager.year)
	_on_budget_changed(StageManager.budget)
	_on_stats_changed()

func _on_turn_changed(turn_in_year: int, season: int, year: int) -> void:
	var season_name = ""
	match season:
		TimeManager.Season.SPRING: season_name = "Spring"
		TimeManager.Season.SUMMER: season_name = "Summer"
		TimeManager.Season.FALL: season_name = "Fall"
		TimeManager.Season.WINTER: season_name = "Winter"
		
	if btn_calendar:
		btn_calendar.text = "%d %s %d" % [TimeManager.turn_in_season, season_name, year]

func _on_stats_changed() -> void:
	if not debug_panel: return
	var b = StageManager.get_active_farm_batch()
	if debug_body: debug_body.text = "Body: %.2f" % b.body
	if debug_acidity: debug_acidity.text = "Acidity: %.2f" % b.acidity
	if debug_sweetness: debug_sweetness.text = "Sweetness: %.2f" % b.sweetness
	if debug_aroma: debug_aroma.text = "Aroma: %.2f" % b.aroma
	if debug_flavor: debug_flavor.text = "Flavor: %.2f" % b.flavor
	if debug_moisture: debug_moisture.text = "Moisture: %.1f%%" % b.moisture
	if debug_defect: debug_defect.text = "Defect: %.1f%%" % b.defect_rate
	if debug_yield: debug_yield.text = "Yield: %dkg" % b.cherry_kg

func _on_budget_changed(budget: int) -> void:
	if btn_money:
		btn_money.text = "$ %d" % budget

func _on_end_turn_pressed() -> void:
	StageManager.advance_turn()
