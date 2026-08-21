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
@onready var debug_bitterness = $main/PanelContainer/DebugStats/Bitterness
@onready var debug_moisture = $main/PanelContainer/DebugStats/Moisture
@onready var debug_defect = $main/PanelContainer/DebugStats/Defect
@onready var debug_yield = $main/PanelContainer/DebugStats/Yield
var debug_yield_mod: Label
var debug_batch_dropdown: OptionButton
var selected_debug_batch_year: int = -1

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
	
	if debug_yield:
		debug_yield_mod = debug_yield.duplicate()
		debug_yield_mod.name = "YieldMod"
		debug_yield.get_parent().add_child(debug_yield_mod)
		debug_yield.get_parent().move_child(debug_yield_mod, debug_yield.get_index())
		
	if debug_panel:
		debug_batch_dropdown = OptionButton.new()
		debug_batch_dropdown.name = "BatchDropdown"
		debug_panel.add_child(debug_batch_dropdown)
		debug_panel.move_child(debug_batch_dropdown, 0)
		debug_batch_dropdown.item_selected.connect(_on_debug_batch_selected)
		# Enable clicking
		debug_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		if debug_panel.get_parent() is Control:
			debug_panel.get_parent().mouse_filter = Control.MOUSE_FILTER_PASS
		
	if btn_end_turn:
		btn_end_turn.pressed.connect(_on_end_turn_pressed)
		
	if btn_menu:
		btn_menu.pressed.connect(func(): _toggle_popup(layer_menu_tabs))
	if btn_journal:
		btn_journal.pressed.connect(func(): _toggle_popup(layer_coffee_log))
		
	_update_all()

	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(_on_card_placement_interaction_requested)


func _toggle_popup(layer: CanvasLayer) -> void:
	if layer:
		layer.visible = !layer.visible
		# Optional: Hide the other popup if one is opened
		if layer == layer_menu_tabs and layer_coffee_log:
			layer_coffee_log.visible = false
		elif layer == layer_coffee_log and layer_menu_tabs:
			layer_menu_tabs.visible = false

func _on_stage_interaction_requested(interaction_name: String, tile_data: Dictionary) -> void:
	var card_data = tile_data.get("data")
	if card_data and card_data.get("custom_result_popup_ui") != null:
		var popup = card_data.custom_result_popup_ui.instantiate()
		add_child(popup)
		if popup.has_method("show_popup"):
			popup.show_popup(tile_data)
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

func _on_debug_batch_selected(index: int) -> void:
	if index >= 0 and index < debug_batch_dropdown.item_count:
		var txt = debug_batch_dropdown.get_item_text(index)
		selected_debug_batch_year = txt.to_int()
		_on_stats_changed()

func _on_stats_changed() -> void:
	if not debug_panel: return
	
	# Update dropdown items
	if debug_batch_dropdown:
		# Save current selection
		var curr_year = selected_debug_batch_year
		if curr_year == -1: curr_year = TimeManager.year
		
		debug_batch_dropdown.clear()
		var idx = 0
		var sel_idx = 0
		var years = StageManager.batches.keys()
		years.sort()
		for y in years:
			debug_batch_dropdown.add_item(str(y))
			if y == curr_year:
				sel_idx = idx
			idx += 1
			
		if debug_batch_dropdown.item_count > 0:
			debug_batch_dropdown.select(sel_idx)
			selected_debug_batch_year = debug_batch_dropdown.get_item_text(sel_idx).to_int()
		else:
			selected_debug_batch_year = -1
			
	var b = null
	if StageManager.batches.has(selected_debug_batch_year):
		b = StageManager.batches[selected_debug_batch_year]
	else:
		b = StageManager.get_active_farm_batch()
		
	if b == null: return
		
	var t = StageManager.current_location.current_tree if (StageManager.current_location and StageManager.current_location.current_tree) else null
	
	if t:
		if debug_body: debug_body.text = "Body: %.2f (Base: %.2f)" % [b.body, t.current_body]
		if debug_acidity: debug_acidity.text = "Acidity: %.2f (Base: %.2f)" % [b.acidity, t.current_acidity]
		if debug_sweetness: debug_sweetness.text = "Sweetness: %.2f (Base: %.2f)" % [b.sweetness, t.current_sweetness]
		if debug_aroma: debug_aroma.text = "Aroma: %.2f (Base: %.2f)" % [b.aroma, t.current_aroma]
		if debug_flavor: debug_flavor.text = "Flavor: %.2f (Base: %.2f)" % [b.flavor, t.current_flavor]
		if debug_bitterness: debug_bitterness.text = "Bitterness: %.2f (Base: %.2f)" % [b.bitterness, t.current_bitterness]
	else:
		if debug_body: debug_body.text = "Body: %.2f" % b.body
		if debug_acidity: debug_acidity.text = "Acidity: %.2f" % b.acidity
		if debug_sweetness: debug_sweetness.text = "Sweetness: %.2f" % b.sweetness
		if debug_aroma: debug_aroma.text = "Aroma: %.2f" % b.aroma
		if debug_flavor: debug_flavor.text = "Flavor: %.2f" % b.flavor
		if debug_bitterness: debug_bitterness.text = "Bitterness: %.2f" % b.bitterness
		
	if debug_moisture: debug_moisture.text = "Moisture: %.1f%%" % b.moisture
	if debug_defect: debug_defect.text = "Defect: %.1f%%" % b.defect_rate
	if debug_yield: debug_yield.text = "Yield: %.2fkg" % b.cherry_kg
	if debug_yield_mod: 
		var hist_str = ", ".join(b.history_log)
		if hist_str.is_empty(): hist_str = "None"
		debug_yield_mod.text = "Yield Mod: %.1f%% (%s)" % [b.accumulated_yield_modifier * 100.0, hist_str]


func _on_budget_changed(budget: int) -> void:
	if btn_money:
		btn_money.text = "$ %d" % budget

func _on_end_turn_pressed() -> void:
	StageManager.advance_turn()

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_data.get("custom_popup_ui") != null:
		var popup = card_data.custom_popup_ui.instantiate()
		add_child(popup)
		if popup.has_method("_on_card_placement_interaction_requested"):
			popup._on_card_placement_interaction_requested(card_name, tile, card_data)
