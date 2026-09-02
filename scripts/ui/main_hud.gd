extends Control

@onready var btn_next_turn = $main/CardPanel/Button

var debug_panel: Control
var debug_body: Label
var debug_acidity: Label
var debug_sweetness: Label
var debug_aroma: Label
var debug_flavor: Label
var debug_bitterness: Label
var debug_yield: Label
var debug_yield_mod: Label
var debug_batch_dropdown: OptionButton
var selected_debug_batch_year: int = -1

# Popup Layers
@onready var layer_menu_tabs = $menu_tabs
@onready var layer_coffee_log = $menu_coffee_log

@export_group("Next Turn Settings")
@export var next_turn_hold_duration: float = 0.5
@export var hold_overlay_color: Color = Color(0.7, 0.35, 0.18, 0.9)

enum NextTurnFillMode {
	RADIAL_CLOCK_WIPE = 0,
	BOTTOM_TO_TOP = 1,
	LEFT_TO_RIGHT = 2,
	CENTER_EXPAND = 3,
	TOP_TO_BOTTOM = 4,
	RIGHT_TO_LEFT = 5,
	HORIZONTAL_SPLIT = 6,
	VERTICAL_SPLIT = 7
}
@export var next_turn_fill_mode: NextTurnFillMode = NextTurnFillMode.RADIAL_CLOCK_WIPE

# Hold Next Turn Variables
var is_holding_next_turn: bool = false
var next_turn_hold_time: float = 0.0
var has_triggered_turn: bool = false

func _ready() -> void:
	StageManager.turn_changed.connect(_on_turn_changed)
	
	StageManager.stats_changed.connect(_on_stats_changed)
	StageManager.interaction_requested.connect(_on_stage_interaction_requested)
	
	_build_debug_panel()
	
	if btn_next_turn:
		btn_next_turn.button_down.connect(func(): is_holding_next_turn = true)
		btn_next_turn.button_up.connect(func(): is_holding_next_turn = false)
		
		# Terapkan shader pintar langsung ke tombol asli!
		var mat = ShaderMaterial.new()
		var shader_file = load("res://shaders/btn_nextturn_effect.gdshader")
		if shader_file == null:
			printerr("GAWAT: SHADER GAGAL DIMUAT! PASTIKAN FILE btn_nextturn_effect.gdshader ADA DI FOLDER shaders DAN DIAKUI OLEH GODOT!")
		else:
			print("SHADER BERHASIL DIMUAT!")
			
		mat.shader = shader_file
		mat.set_shader_parameter("progress", 0.0)
		mat.set_shader_parameter("tint_color", hold_overlay_color)
		btn_next_turn.material = mat
		
	var top_bar_node = $main/top_bar
	if top_bar_node:
		top_bar_node.menu_pressed.connect(func(): _toggle_popup(layer_menu_tabs))
		top_bar_node.journal_pressed.connect(func(): _toggle_popup(layer_coffee_log))
		
	_update_all()

	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(_on_card_placement_interaction_requested)

func _process(delta: float) -> void:
	if btn_next_turn and not btn_next_turn.disabled:
		var is_holding = is_holding_next_turn or Input.is_action_pressed("next_turn")
		
		# Simulasi tombol ditekan (mengubah tampilan ke 'pressed' style)
		var current_state = "pressed" if is_holding else "normal"
		
		# Ambil style normal yang asli (yang diset di editor) jika belum disimpan
		if not btn_next_turn.has_meta("original_normal_style"):
			var og_style = btn_next_turn.get_theme_stylebox("normal")
			btn_next_turn.set_meta("original_normal_style", og_style)
			
		if is_holding:
			# Paksa style normal menjadi style pressed
			btn_next_turn.add_theme_stylebox_override("normal", btn_next_turn.get_theme_stylebox("pressed"))
		else:
			# Kembalikan style normal ke aslinya
			if btn_next_turn.has_meta("original_normal_style"):
				btn_next_turn.add_theme_stylebox_override("normal", btn_next_turn.get_meta("original_normal_style"))
				
		# --- SINKRONISASI SHADER ---
		if btn_next_turn.material:
			var mat: ShaderMaterial = btn_next_turn.material
			# Beritahu shader ukurannya
			mat.set_shader_parameter("button_size", btn_next_turn.size)
			mat.set_shader_parameter("fill_mode", next_turn_fill_mode)
		# -----------------------------------------------------------
			
		if is_holding and not has_triggered_turn:
			next_turn_hold_time += delta
			var progress = clamp(next_turn_hold_time / next_turn_hold_duration, 0.0, 1.0)
			
			if btn_next_turn.material:
				btn_next_turn.material.set_shader_parameter("progress", progress)
			
			# Jika hold sudah penuh, picu Next Turn!
			if next_turn_hold_time >= next_turn_hold_duration:
				has_triggered_turn = true  # Kunci agar tidak spam!
				next_turn_hold_time = 0.0   # Reset waktu
				if btn_next_turn.material: btn_next_turn.material.set_shader_parameter("progress", 0.0)
				_on_next_turn_pressed()
		
		elif not is_holding:
			has_triggered_turn = false # Buka kunci setelah dilepas
			
			# Jika dilepas sebelum penuh, reset mundur dengan cepat (selalu butuh ~0.25 detik untuk kembali ke 0)
			if next_turn_hold_time > 0:
				var reset_speed = next_turn_hold_duration / 0.25
				next_turn_hold_time -= reset_speed * delta
				if next_turn_hold_time < 0:
					next_turn_hold_time = 0.0
					
				var progress = clamp(next_turn_hold_time / next_turn_hold_duration, 0.0, 1.0)
				if btn_next_turn.material:
					btn_next_turn.material.set_shader_parameter("progress", progress)

func _build_debug_panel() -> void:
	var container = PanelContainer.new()
	container.name = "PanelContainer"
	$main.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	container.offset_left = 20
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	debug_panel = VBoxContainer.new()
	debug_panel.name = "DebugStats"
	debug_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	container.add_child(debug_panel)
	
	debug_batch_dropdown = OptionButton.new()
	debug_batch_dropdown.name = "BatchDropdown"
	debug_batch_dropdown.item_selected.connect(_on_debug_batch_selected)
	debug_panel.add_child(debug_batch_dropdown)
	
	debug_body = Label.new()
	debug_panel.add_child(debug_body)
	debug_acidity = Label.new()
	debug_panel.add_child(debug_acidity)
	debug_sweetness = Label.new()
	debug_panel.add_child(debug_sweetness)
	debug_aroma = Label.new()
	debug_panel.add_child(debug_aroma)
	debug_flavor = Label.new()
	debug_panel.add_child(debug_flavor)
	debug_bitterness = Label.new()
	debug_panel.add_child(debug_bitterness)
	debug_yield = Label.new()
	debug_panel.add_child(debug_yield)
	debug_yield_mod = Label.new()
	debug_panel.add_child(debug_yield_mod)

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
		if btn_next_turn: btn_next_turn.disabled = true

func _update_all() -> void:
	_on_turn_changed(TimeManager.turn_in_year, TimeManager.season, TimeManager.year)
	_on_stats_changed()

func _on_turn_changed(turn_in_year: int, season: int, year: int) -> void:
	pass

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
		
	if debug_yield: debug_yield.text = "Yield: %.2fkg" % b.cherry_kg
	if debug_yield_mod: 
		var hist_str = ", ".join(b.history_log)
		if hist_str.is_empty(): hist_str = "None"
		debug_yield_mod.text = "Yield Mod: %.1f%% (%s)" % [b.accumulated_yield_modifier * 100.0, hist_str]


func _on_next_turn_pressed() -> void:
	# 1. Tutup layar pakai transisi
	await TransitionManager.fade_out()
	
	# 2. Majukan turn di belakang layar yang sedang gelap
	StageManager.advance_turn()
	
	# 3. Buka lagi layarnya
	TransitionManager.fade_in()

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_data.get("custom_popup_ui") != null:
		var popup = card_data.custom_popup_ui.instantiate()
		add_child(popup)
		if popup.has_method("_on_card_placement_interaction_requested"):
			popup._on_card_placement_interaction_requested(card_name, tile, card_data)
