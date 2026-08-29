extends CanvasLayer

@onready var hbox_methods = $popup_panel/margin/hbox/right_side/margin/method_container/option
@onready var slider_container = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container
@onready var slider_intensity = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container/slider
@onready var lbl_intensity_val = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container/label

@onready var btn_confirm = $popup_panel/margin/hbox/right_side/margin/method_container/confirm
@onready var btn_close = $popup_panel/close
@onready var btn_info = $popup_panel/Control/title_container/info_button

@onready var lbl_farm_name = $popup_panel/margin/hbox/left_side/margin/content/terroir/lbl_terroir
@onready var lbl_arabica = $popup_panel/margin/hbox/left_side/margin/content/terroir/lbl_arabica
@onready var lbl_robusta = $popup_panel/margin/hbox/left_side/margin/content/terroir/lbl_robusta
@onready var val_variety = $popup_panel/margin/hbox/left_side/margin/content/variety/value

@onready var radar_graph = $popup_panel/margin/hbox/left_side/margin/content/chart/radar
@onready var cont_cost = $popup_panel/margin/hbox/left_side/margin/content/cost/HBoxContainer
@onready var val_cost = $popup_panel/margin/hbox/left_side/margin/content/cost/HBoxContainer/value

var available_methods: Array[ProcessMethodData] = []
var selected_method: ProcessMethodData
var method_btn_template: Button

var current_tile: Node3D
var current_card_data: Resource

# Variables that hold the currently evaluated levels (if slider is used)
var mod_acidity: float = 0.0
var mod_aroma: float = 0.0
var mod_sweetness: float = 0.0
var mod_flavor: float = 0.0
var mod_body: float = 0.0
var mod_bitterness: float = 0.0
var mod_defect: float = 0.0
var mod_quant_pct: float = 0.0

func _ready() -> void:
	if hbox_methods and hbox_methods.has_node("opt1"):
		method_btn_template = hbox_methods.get_node("opt1").duplicate()
	elif hbox_methods and hbox_methods.has_node("opt"):
		method_btn_template = hbox_methods.get_node("opt").duplicate()
		
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
	
	_build_method_buttons()
	
	if slider_intensity:
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
		btn.text = method.method_name
		btn.pressed.connect(func(): _select_method(method))
		hbox_methods.add_child(btn)
		
	if available_methods.size() > 0:
		pass

func _select_method(method: ProcessMethodData) -> void:
	if selected_method == method:
		selected_method = null
	else:
		selected_method = method
		
	_update_ui()
	
func _update_ui() -> void:
	for child in hbox_methods.get_children():
		if child is Button:
			if selected_method and child.text == selected_method.method_name:
				child.set_pressed_no_signal(true)
			else:
				child.set_pressed_no_signal(false)

	if val_cost:
		val_cost.visible = true
		if selected_method:
			val_cost.text = "%d" % selected_method.override_cost
			if cont_cost: cont_cost.show()
		else:
			val_cost.text = "0"
			if cont_cost: cont_cost.hide()
			
	if selected_method:
		btn_confirm.disabled = false
		
		# Base values (if no slider is used)
		mod_acidity = selected_method.mod_acidity
		mod_aroma = selected_method.mod_aroma
		mod_sweetness = selected_method.mod_sweetness
		mod_flavor = selected_method.mod_flavor
		mod_body = selected_method.mod_body
		mod_bitterness = selected_method.mod_bitterness
		mod_defect = selected_method.mod_defect
		mod_quant_pct = selected_method.mod_quant_pct
		
		if selected_method.slider_levels.size() > 0:
			slider_container.show()
			_on_slider_changed(slider_intensity.value)
		else:
			slider_container.hide()
			if radar_graph:
				radar_graph.set_item_value(0, selected_method.radar_ripeness)
				radar_graph.set_item_value(1, selected_method.radar_quantity)
				radar_graph.set_item_value(2, selected_method.radar_quality)
	else:
		btn_confirm.disabled = true
		slider_container.hide()
		if radar_graph:
			radar_graph.set_item_value(0, 0.0)
			radar_graph.set_item_value(1, 0.0)
			radar_graph.set_item_value(2, 0.0)

func _on_slider_changed(val: float) -> void:
	if not selected_method or selected_method.slider_levels.size() == 0:
		return
		
	var idx = 0
	if val <= 0: idx = 0
	elif val <= 25: idx = 1
	elif val <= 50: idx = 2
	elif val <= 75: idx = 3
	else: idx = 4
	
	idx = clampi(idx, 0, selected_method.slider_levels.size() - 1)
	var level = selected_method.slider_levels[idx]
	
	mod_acidity = level.mod_acidity
	mod_aroma = level.mod_aroma
	mod_sweetness = level.mod_sweetness
	mod_flavor = level.mod_flavor
	mod_body = level.mod_body
	mod_bitterness = level.mod_bitterness
	mod_defect = level.mod_defect
	mod_quant_pct = level.mod_quant_pct
	
	lbl_intensity_val.text = level.level_name
	
	if radar_graph:
		radar_graph.set_item_value(0, level.radar_ripeness)
		radar_graph.set_item_value(1, level.radar_quantity)
		radar_graph.set_item_value(2, level.radar_quality)

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name != "Harvest":
		return
		
	current_tile = tile
	current_card_data = card_data
	
	if current_card_data and current_card_data.get("popup_methods"):
		available_methods = current_card_data.popup_methods
	else:
		available_methods = []
		
	selected_method = null
	
	if StageManager.current_location and StageManager.current_location.variety_data:
		var v_data = StageManager.current_location.variety_data
		if val_variety:
			val_variety.text = v_data.variety_name
		if lbl_arabica and lbl_robusta:
			if v_data.species_name.to_lower() == "arabica":
				lbl_arabica.show()
				lbl_robusta.hide()
			else:
				lbl_arabica.hide()
				lbl_robusta.show()
			
	if radar_graph:
		radar_graph.set_item_value(0, 0.0)
		radar_graph.set_item_value(1, 0.0)
		radar_graph.set_item_value(2, 0.0)
	
	_build_method_buttons()
	_update_ui()
	
	show()

func _on_confirm() -> void:
	if selected_method == null:
		return
		
	queue_free()
	
	var extra_data = {
		"method_name": selected_method.method_name,
		"cost": selected_method.override_cost,
		"duration": selected_method.turn_duration,
		"mod_acidity": mod_acidity,
		"mod_aroma": mod_aroma,
		"mod_sweetness": mod_sweetness,
		"mod_flavor": mod_flavor,
		"mod_body": mod_body,
		"mod_bitterness": mod_bitterness,
		"mod_defect": mod_defect,
		"mod_quant_pct": mod_quant_pct
	}
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Harvest", current_tile, current_card_data, extra_data)
		
	current_tile = null
	current_card_data = null

func _on_cancel() -> void:
	queue_free()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Harvest", current_tile, current_card_data)
	current_tile = null
	current_card_data = null

