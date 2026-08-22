extends CanvasLayer

@onready var hbox_methods = $CenterContainer/PanelContainer/VBox/Split/RightPanel/HBoxMethods
@onready var slider_hbox = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox
@onready var slider_intensity = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/SliderIntensity
@onready var lbl_intensity_val = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/LblIntensityVal

@onready var btn_confirm = $new_popup_panel/center/vbox/detail/background/vbox/hbox/setting/vbox/button_confirm
@onready var btn_close = $new_popup_panel/center/vbox/header/close/close_button

@onready var val_ripeness = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VRip
@onready var val_quality = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQual
@onready var val_quantity = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQuant

@onready var lbl_farm_name = $new_popup_panel/center/vbox/detail/background/vbox/hbox/stat/vbox/area_name/label
@onready var val_plant = $new_popup_panel/center/vbox/detail/background/vbox/hbox/stat/vbox/plant/value
@onready var timeline_container = $new_popup_panel/center/vbox/detail/background/vbox/timeline/timeline

var available_methods: Array[ProcessMethodData] = []
var selected_method: ProcessMethodData

var mod_acidity: float = 0.0
var mod_aroma: float = 0.0
var mod_sweetness: float = 0.0
var mod_flavor: float = 0.0
var mod_body: float = 0.0
var mod_bitterness: float = 0.0
var mod_quant_pct: float = 0.0

var current_tile: Node3D
var current_card_data: Resource

func _ready() -> void:
	$CenterContainer/PanelContainer/VBox/Header/LblTitle.text = "PRUNING"
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
	
	_load_methods()
	_build_method_buttons()
	
	slider_intensity.value = 50.0
	slider_intensity.value_changed.connect(_on_slider_changed)
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(_on_card_placement_interaction_requested)
	
	UIUtils.setup_input_blocker(self)
	hide()

func _load_methods() -> void:
	var path = "res://resources/methods/pruning/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(path + file_name) as ProcessMethodData
				if res:
					available_methods.append(res)
			file_name = dir.get_next()

func _build_method_buttons() -> void:
	for child in hbox_methods.get_children():
		child.queue_free()
		
	for method in available_methods:
		var btn = Button.new()
		btn.text = method.method_name
		btn.custom_minimum_size = Vector2(150, 100)
		btn.pressed.connect(func(): _select_method(method))
		hbox_methods.add_child(btn)

func _select_method(method: ProcessMethodData) -> void:
	selected_method = method
	slider_hbox.show()
	
	for child in hbox_methods.get_children():
		if child is Button:
			if child.text == method.method_name:
				child.modulate = Color(0.2, 0.8, 0.2)
			else:
				child.modulate = Color(1.0, 1.0, 1.0)
				
	_on_slider_changed(slider_intensity.value)

func _on_slider_changed(val: float) -> void:
	if not selected_method:
		return
		
	# Fallback to the old math formula ONLY if slider_levels is empty
	if selected_method.slider_levels.size() == 0:
		return
		
	var idx = 0
	if val <= 0: idx = 0
	elif val <= 25: idx = 1
	elif val <= 50: idx = 2
	elif val <= 75: idx = 3
	else: idx = 4
	
	# Clamp index just in case the array is smaller than 5
	idx = clampi(idx, 0, selected_method.slider_levels.size() - 1)
	var level = selected_method.slider_levels[idx]
	
	# Extract exactly from the resource! No math needed!
	mod_acidity = level.mod_acidity
	mod_aroma = level.mod_aroma
	mod_sweetness = level.mod_sweetness
	mod_flavor = level.mod_flavor
	mod_body = level.mod_body
	mod_bitterness = level.mod_bitterness
	mod_quant_pct = level.mod_quant_pct
	
	# UI Visuals
	lbl_intensity_val.text = level.level_name
	
	val_ripeness.text = level.ui_rip_text
	val_ripeness.add_theme_color_override("font_color", level.ui_rip_color)
	
	val_quality.text = level.ui_qual_text
	val_quality.add_theme_color_override("font_color", level.ui_qual_color)
	
	val_quantity.text = level.ui_quant_text
	val_quantity.add_theme_color_override("font_color", level.ui_quant_color)


func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Pruning":
		current_tile = tile
		current_card_data = card_data
		show_popup()

func show_popup() -> void:
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
		if StageManager.current_location.variety_data:
			val_plant.text = StageManager.current_location.variety_data.variety_name
	
	_update_timeline()
	selected_method = null
	slider_hbox.hide()
	
	# Reset button colors
	for child in hbox_methods.get_children():
		if child is Button:
			child.modulate = Color(1.0, 1.0, 1.0)
			
	slider_intensity.value = 50.0
	show()

func _update_timeline() -> void:
	var pending_id = ""
	if current_card_data and current_card_data.get("process_id"):
		pending_id = current_card_data.process_id
	UIUtils.build_farm_timeline(timeline_container, 16, 16, 10, 2, pending_id)

func _on_confirm() -> void:
	if selected_method == null:
		return
		
	hide()
	if has_node("/root/EventManager") and selected_method != null:
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Pruning", current_tile, current_card_data, {
			"pruning_method": selected_method.method_name,
			"pruning_intensity": slider_intensity.value,
			"mod_acidity": mod_acidity,
			"mod_aroma": mod_aroma,
			"mod_sweetness": mod_sweetness,
			"mod_flavor": mod_flavor,
			"mod_body": mod_body,
			"mod_bitterness": mod_bitterness,
			"mod_quant_pct": mod_quant_pct
		})
	current_tile = null
	current_card_data = null

func _on_cancel() -> void:
	hide()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Pruning", current_tile, current_card_data)
	current_tile = null
	current_card_data = null
