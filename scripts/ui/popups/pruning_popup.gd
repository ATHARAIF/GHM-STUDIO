extends CanvasLayer

#@onready var hbox_methods = $popup_panel/margin/hbox/right_side/margin/method_container/option
#@onready var slider_container = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container
#@onready var slider_intensity = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container/slider
#@onready var lbl_intensity_val = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container/label
#
#@onready var btn_confirm = $popup_panel/margin/hbox/right_side/margin/method_container/confirm
#@onready var btn_close = $popup_panel/close
#@onready var btn_info = $popup_panel/Control/title_container/info_button
#
#@onready var lbl_farm_name = $popup_panel/margin/hbox/left_side/margin/content/terroir/lbl_terroir
#@onready var lbl_arabica = $popup_panel/margin/hbox/left_side/margin/content/terroir/lbl_arabica
#@onready var lbl_robusta = $popup_panel/margin/hbox/left_side/margin/content/terroir/lbl_robusta
#@onready var val_variety = $popup_panel/margin/hbox/left_side/margin/content/variety/value
#
#@onready var radar_graph = $popup_panel/margin/hbox/left_side/margin/content/chart/radar

@onready var hbox_methods = $CenterContainer/panel/content/bean_detail/left/toggle/toggle_buttons
@onready var slider_container = $CenterContainer/panel/content/bean_detail/left/slider
@onready var slider_intensity = $CenterContainer/panel/content/bean_detail/left/slider/container/slider
@onready var lbl_intensity_val = $CenterContainer/panel/content/bean_detail/left/slider/container/value

@onready var btn_confirm = $CenterContainer/panel/content/confirmation/confirm
@onready var btn_close = $CenterContainer/panel/close

@onready var lbl_farm_name = $CenterContainer/panel/content/bean_name/terroir
@onready var lbl_arabica = $CenterContainer/panel/content/bean_name/arabica
@onready var lbl_robusta = $CenterContainer/panel/content/bean_name/robusta

@onready var val_variety = $CenterContainer/panel/content/bean_detail/left/bean_data/data1/value

@onready var radar_graph = $CenterContainer/panel/content/bean_detail/left/chart/radar

var available_methods: Array[ProcessMethodData] = []
var selected_method: ProcessMethodData
var val_cost: Label

var mod_health: float = 0.0
var mod_acidity: float = 0.0
var mod_aroma: float = 0.0
var mod_sweetness: float = 0.0
var mod_flavor: float = 0.0
var mod_body: float = 0.0
var mod_bitterness: float = 0.0
var mod_quant_pct: float = 0.0

var current_tile: Node3D
var current_card_data: Resource
var method_btn_template: Button

func _ready() -> void:
	if hbox_methods and hbox_methods.has_node("opt"):
		method_btn_template = hbox_methods.get_node("opt").duplicate()
		
	# lbl_title.text = "PRUNING" # If needed
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
	
	_build_method_buttons()
	
	slider_intensity.value = 50.0
	slider_intensity.value_changed.connect(_on_slider_changed)
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	
	UIUtils.setup_input_blocker(self)
	hide()

func _build_method_buttons() -> void:
	for child in hbox_methods.get_children():
		child.queue_free()
		
	if not method_btn_template:
		return
		
	available_methods.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	for method in available_methods:
		var btn = method_btn_template.duplicate()
		btn.show()
		
		# Set text directly onto the button, since the new design doesn't use child labels
		btn.text = method.method_name
		
		# Jika ada icon di method data, set di sini
		# var icon = btn.get_node_or_null("info/icon")
		# if icon and method.method_icon: icon.texture = method.method_icon
		
		btn.pressed.connect(func(): _select_method(method))
		hbox_methods.add_child(btn)

func _select_method(method: ProcessMethodData) -> void:
	if selected_method == method:
		selected_method = null
	else:
		selected_method = method
		
	btn_confirm.disabled = (selected_method == null)
	if selected_method:
		slider_container.show()
		_on_slider_changed(slider_intensity.value)
	else:
		slider_container.hide()
		if radar_graph:
			radar_graph.set_item_value(0, 0.0)
			radar_graph.set_item_value(1, 0.0)
			radar_graph.set_item_value(2, 0.0)
	
	for child in hbox_methods.get_children():
		if child is Button:
			var is_selected = (selected_method and child.text == selected_method.method_name)
			child.set_pressed_no_signal(is_selected)
			
	if not selected_method:
		# TODO: Reset RadarGraph later
		return
		
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
	mod_health = level.mod_health
	mod_acidity = level.mod_acidity
	mod_aroma = level.mod_aroma
	mod_sweetness = level.mod_sweetness
	mod_flavor = level.mod_flavor
	mod_body = level.mod_body
	mod_bitterness = level.mod_bitterness
	mod_quant_pct = level.mod_quant_pct
	
	# UI Visuals
	lbl_intensity_val.text = level.level_name
	
	if radar_graph:
		radar_graph.set_item_value(0, level.radar_ripeness)
		radar_graph.set_item_value(1, level.radar_quantity)
		radar_graph.set_item_value(2, level.radar_quality)
	
	# TODO: Update RadarGraph with level.ui_rip_text, etc.


func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Pruning":
		current_tile = tile
		current_card_data = card_data
		show_popup()

func show_popup() -> void:
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
		
		lbl_arabica.hide()
		lbl_robusta.hide()
		
		if StageManager.current_location.variety_data:
			if StageManager.current_location.variety_data.species_name.to_lower() == "arabica":
				lbl_arabica.show()
			elif StageManager.current_location.variety_data.species_name.to_lower() == "robusta":
				lbl_robusta.show()
			
			if val_variety: val_variety.text = StageManager.current_location.variety_data.variety_name
	
	selected_method = null
	slider_container.hide()
	
	if radar_graph:
		radar_graph.set_item_value(0, 0.0)
		radar_graph.set_item_value(1, 0.0)
		radar_graph.set_item_value(2, 0.0)
	
	# Reset button colors
	for child in hbox_methods.get_children():
		if child is Button:
			child.set_pressed_no_signal(false)
			
	slider_intensity.value = 50.0
	
	if current_card_data:
		available_methods = current_card_data.popup_methods
	_build_method_buttons()
	
	_reset_ui()
	show()



func _on_confirm() -> void:
	if selected_method == null:
		return
		
	queue_free()
	if has_node("/root/EventManager") and selected_method != null:
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Pruning", current_tile, current_card_data, {
			"pruning_method": selected_method.method_name,
			"pruning_intensity": slider_intensity.value,
			"mod_health": mod_health,
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
	queue_free()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Pruning", current_tile, current_card_data)
	current_tile = null
	current_card_data = null


func _reset_ui() -> void:
	selected_method = null
	btn_confirm.disabled = true
	
	# TODO: Reset RadarGraph later
	
	for child in hbox_methods.get_children():
		if child is Button:
			child.set_pressed_no_signal(false)

	slider_container.hide()
