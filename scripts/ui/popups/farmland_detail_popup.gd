extends CanvasLayer

@onready var lbl_title = $CenterContainer/panel/panel_label
@onready var btn_close = $CenterContainer/panel/close
#header
@onready var farmland_name = $CenterContainer/panel/content/header/farmland_name
#header - timeline
@onready var planting = $CenterContainer/panel/content/header/timeline/planting
@onready var lbl_react1 = $CenterContainer/panel/content/header/timeline/pla_to_weed
@onready var weeding = $CenterContainer/panel/content/header/timeline/weeding
@onready var lbl_react2 = $CenterContainer/panel/content/header/timeline/weed_to_pru
@onready var pruning = $CenterContainer/panel/content/header/timeline/pruning
@onready var lbl_react3 = $CenterContainer/panel/content/header/timeline/pru_to_suck
@onready var suckering = $CenterContainer/panel/content/header/timeline/suckering
@onready var lbl_react4 = $CenterContainer/panel/content/header/timeline/suck_to_harv
@onready var harvest = $CenterContainer/panel/content/header/timeline/harvest

#farmland detail - left
@onready var value_surface = $CenterContainer/panel/content/farmland_detail/left/data/surface/value
@onready var value_altitude = $CenterContainer/panel/content/farmland_detail/left/data/altitude/value
@onready var value_slope = $CenterContainer/panel/content/farmland_detail/left/data/slope/value
@onready var value_soilph = $CenterContainer/panel/content/farmland_detail/left/data/soil_ph/value
	#soil
@onready var icon_sand = $CenterContainer/panel/content/farmland_detail/left/data/soil/container/sand/TextureRect
@onready var value_sand = $CenterContainer/panel/content/farmland_detail/left/data/soil/container/sand/value
@onready var icon_clay = $CenterContainer/panel/content/farmland_detail/left/data/soil/container/clay/TextureRect
@onready var value_clay = $CenterContainer/panel/content/farmland_detail/left/data/soil/container/clay/value
@onready var icon_loam = $CenterContainer/panel/content/farmland_detail/left/data/soil/container/loam/TextureRect
@onready var value_loam = $CenterContainer/panel/content/farmland_detail/left/data/soil/container/loam/value
	#plantation
@onready var value_species = $CenterContainer/panel/content/farmland_detail/left/data/plantation/species/value
@onready var value_variety = $CenterContainer/panel/content/farmland_detail/left/data/plantation/variety/value
@onready var value_age = $CenterContainer/panel/content/farmland_detail/left/data/plantation/age/value
@onready var value_density = $CenterContainer/panel/content/farmland_detail/left/data/plantation/density/value
@onready var value_health = $CenterContainer/panel/content/farmland_detail/left/data/plantation/health/value

func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(func(): self.hide())
		
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(func(_a, _b, _c): self.hide())
		
	UIUtils.setup_input_blocker(self)

func _get_color_for_range(val: float, ideal_min: float, ideal_max: float, safe_min: float, safe_max: float) -> Color:
	if val >= ideal_min and val <= ideal_max:
		return Color(0.2, 0.8, 0.2) # Green
	elif val >= safe_min and val <= safe_max:
		return Color(0.8, 0.8, 0.2) # Yellow
	else:
		return Color(0.8, 0.2, 0.2) # Red

func setup_data(location: FarmLocation) -> void:
	if not location:
		return
		
	if farmland_name:
		farmland_name.text = location.location_name
		
	var var_data = location.variety_data
	var tree = location.current_tree
	
	if value_surface:
		value_surface.text = "%.1f Ha" % location.surface_area
		value_surface.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		
	if value_altitude:
		value_altitude.text = "%d masl" % location.altitude
		if var_data:
			value_altitude.add_theme_color_override("font_color", _get_color_for_range(location.altitude, var_data.ideal_altitude_min, var_data.ideal_altitude_max, var_data.safe_altitude_min, var_data.safe_altitude_max))
			
	if value_slope:
		value_slope.text = "%.0f%%" % location.slope
		if var_data:
			value_slope.add_theme_color_override("font_color", _get_color_for_range(location.slope, var_data.ideal_slope_min, var_data.ideal_slope_max, var_data.safe_slope_min, var_data.safe_slope_max))
			
	if value_soilph:
		value_soilph.text = "%.1f" % location.ph_level
		if var_data:
			value_soilph.add_theme_color_override("font_color", _get_color_for_range(location.ph_level, var_data.ideal_ph_min, var_data.ideal_ph_max, var_data.safe_ph_min, var_data.safe_ph_max))
			
	if value_sand:
		
		value_sand.text = "%.0f%%" % location.soil_sand
		if var_data:
			value_sand.add_theme_color_override("font_color", _get_color_for_range(location.soil_sand, var_data.ideal_sand_min, var_data.ideal_sand_max, 0, 100))
			
	if value_clay:
		
		value_clay.text = "%.0f%%" % location.soil_clay
		if var_data:
			value_clay.add_theme_color_override("font_color", _get_color_for_range(location.soil_clay, var_data.ideal_clay_min, var_data.ideal_clay_max, 0, 100))
			
	if value_loam:
		
		value_loam.text = "%.0f%%" % location.soil_loam
		value_loam.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		
	if tree:
		if value_species:
			value_species.text = var_data.species_name if var_data else "Unknown"
		if value_variety:
			value_variety.text = var_data.variety_name if var_data else "Unknown"
		if value_age:
			value_age.text = "%.0f Years" % tree.age_years
			value_age.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2) if tree.age_years < 3 else Color(0.2, 0.8, 0.2))
		if value_density:
			value_density.text = "%d Trees/Ha" % tree.planting_density
			if var_data:
				value_density.add_theme_color_override("font_color", _get_color_for_range(tree.planting_density, var_data.ideal_density_min, var_data.ideal_density_max, var_data.safe_density_min, var_data.safe_density_max))
		if value_health:
			value_health.text = "%.0f%%" % tree.health_pct
			value_health.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
	else:
		if value_species: value_species.text = "-"
		if value_variety: value_variety.text = "-"
		if value_age: value_age.text = "-"
		if value_density: value_density.text = "-"
		if value_health: value_health.text = "-"
		
	_update_timeline()

func _update_timeline() -> void:
	var process_map = ["FP00", "FP01", "FP02", "FP03", "FP04"]
	var timeline_nodes = [planting, weeding, pruning, suckering, harvest]
	var connectors = [lbl_react1, lbl_react2, lbl_react3, lbl_react4]
	
	var active_batch = null
	if has_node("/root/StageManager"):
		active_batch = get_node("/root/StageManager").get_active_farm_batch()
		
	var active_tiles = []
	if has_node("/root/StageManager"):
		active_tiles = get_node("/root/StageManager").active_tiles
		
	var statuses = []
	
	for i in range(5):
		var node = timeline_nodes[i]
		
		var p_id = process_map[i]
		var is_completed = false
		if active_batch and active_batch.completed_processes.has(p_id):
			is_completed = true
			
		var is_processing = false
		for dict in active_tiles:
			if dict.has("data") and dict.data.process_id == p_id:
				is_processing = true
				break
				
		# Planting selalu dianggap selesai jika sudah ada pohon
		if i == 0:
			is_completed = true
			
		var status = "IDLE"
		var progress = 0.0
		
		# Cek Turn Limit untuk mendeteksi 'Skipped'
		var end_turns = [0, 11, 11, 13, 16]
		var curr_turn = 0
		if has_node("/root/TimeManager"):
			curr_turn = get_node("/root/TimeManager").turn_in_year
		
		if is_completed:
			status = "COMPLETED"
			progress = 100.0
		elif is_processing:
			status = "IN_PROGRESS"
			progress = 50.0
		elif curr_turn > end_turns[i]:
			status = "SKIPPED"
			progress = 0.0
		else:
			status = "IDLE"
			progress = 0.0
			
		statuses.append(status)
			
		if node and node.has_method("set_state"):
			node.set_state(status, progress)

	# Warnai Garis Penghubung (Connectors)
	for i in range(4):
		var connector = connectors[i]
		if not connector: continue
		
		# Jika fase tujuan (i+1) sedang berjalan atau sudah selesai, nyalakan garisnya!
		var next_status = statuses[i]
		if next_status == "COMPLETED":
			connector.modulate = Color(0.2, 0.8, 0.4) # Hijau
		elif next_status == "IN_PROGRESS":
			connector.modulate = Color(1.0, 0.8, 0.2) # Oranye/Kuning
		else:
			connector.modulate = Color(0.706, 0.714, 0.706, 1.0) # Abu-abu redup
