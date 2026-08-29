extends Node3D

@onready var popup_ui: CanvasLayer = $PopupUI
@onready var lbl_location: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/LblLocation
@onready var btn_close: Button = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/BtnClose
@onready var timeline_container: HBoxContainer = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Timeline
@onready var grid: GridContainer = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/GridContainer

var location: FarmLocation

func _ready() -> void:
	# Hubungkan references manual jika tidak ada
	popup_ui = $PopupUI
	lbl_location = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/LblLocation
	btn_close = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/BtnClose
	timeline_container = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Timeline
	grid = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/GridContainer
	
	location = StageManager.current_location
	
	_build_ui()
		
	btn_close.pressed.connect(func(): popup_ui.hide())
	popup_ui.hide()
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(func(_a, _b, _c): popup_ui.hide())
		
	UIUtils.setup_input_blocker(popup_ui)

func _get_color_for_range(val: float, ideal_min: float, ideal_max: float, safe_min: float, safe_max: float) -> Color:
	if val >= ideal_min and val <= ideal_max:
		return Color(0.2, 0.8, 0.2) # Green
	elif val >= safe_min and val <= safe_max:
		return Color(0.8, 0.8, 0.2) # Yellow
	else:
		return Color(0.8, 0.2, 0.2) # Red

func _add_header(title: String) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	grid.add_child(spacer)
	
	var spacer2 = Control.new()
	grid.add_child(spacer2)
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0)) # Light Blue
	lbl_title.add_theme_font_size_override("font_size", 13)
	grid.add_child(lbl_title)
	
	var empty = Control.new()
	grid.add_child(empty)

func _add_row(title: String, val_text: String, color: Color = Color.WHITE) -> void:
	var lbl_title = Label.new()
	lbl_title.text = title
	grid.add_child(lbl_title)
	
	var lbl_val = Label.new()
	lbl_val.text = val_text
	lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_val.add_theme_color_override("font_color", color)
	grid.add_child(lbl_val)

func _build_ui() -> void:
	if not location:
		return
		
	lbl_location.text = location.location_name
	
	for child in grid.get_children():
		child.queue_free()
		
	var var_data = location.variety_data
	var tree = location.current_tree
	
	_add_header("--- GEOGRAPHY ---")
	_add_row("Surface Area", "%.1f Ha" % location.surface_area, Color(0.2, 0.8, 0.2))
	
	var alt_color = Color.WHITE
	if var_data: alt_color = _get_color_for_range(location.altitude, var_data.ideal_altitude_min, var_data.ideal_altitude_max, var_data.safe_altitude_min, var_data.safe_altitude_max)
	_add_row("Altitude (masl)", "%d masl" % location.altitude, alt_color)
	
	var slope_color = Color.WHITE
	if var_data: slope_color = _get_color_for_range(location.slope, var_data.ideal_slope_min, var_data.ideal_slope_max, var_data.safe_slope_min, var_data.safe_slope_max)
	_add_row("Land Slope", "%.0f%%" % location.slope, slope_color)
	
	_add_header("--- SOIL TERROIR ---")
	var ph_color = Color.WHITE
	if var_data: ph_color = _get_color_for_range(location.ph_level, var_data.ideal_ph_min, var_data.ideal_ph_max, var_data.safe_ph_min, var_data.safe_ph_max)
	_add_row("Soil pH", "%.1f" % location.ph_level, ph_color)
	
	var sand_color = Color.WHITE
	if var_data: sand_color = _get_color_for_range(location.soil_sand, var_data.ideal_sand_min, var_data.ideal_sand_max, 0, 100)
	_add_row("Sand Content", "%.0f%%" % location.soil_sand, sand_color)
	
	var clay_color = Color.WHITE
	if var_data: clay_color = _get_color_for_range(location.soil_clay, var_data.ideal_clay_min, var_data.ideal_clay_max, 0, 100)
	_add_row("Clay Content", "%.0f%%" % location.soil_clay, clay_color)
	
	_add_row("Loam Content", "%.0f%%" % location.soil_loam, Color(0.2, 0.8, 0.2))
	
	if tree:
		_add_header("--- PLANTATION ---")
		_add_row("Coffee Species", var_data.species_name if var_data else "Unknown", Color(0.2, 0.8, 0.8))
		_add_row("Coffee Variety", var_data.variety_name if var_data else "Unknown", Color(0.2, 0.8, 0.8))
		_add_row("Tree Age", "%.0f Years" % tree.age_years, Color(0.8, 0.2, 0.2) if tree.age_years < 3 else Color(0.2, 0.8, 0.2))
		
		var den_color = Color.WHITE
		if var_data: den_color = _get_color_for_range(tree.planting_density, var_data.ideal_density_min, var_data.ideal_density_max, var_data.safe_density_min, var_data.safe_density_max)
		_add_row("Planting Density", "%d Trees/Ha" % tree.planting_density, den_color)
		
		_add_row("Tree Health", "%.0f%%" % tree.health_pct, Color(0.8, 0.8, 0.2))

func _update_timeline() -> void:
	UIUtils.build_farm_timeline(timeline_container, 24, 30, 12, 4)

func _on_static_body_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_timeline()
		_build_ui()
		popup_ui.show()

