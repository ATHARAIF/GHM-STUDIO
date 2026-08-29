extends CanvasLayer

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

@onready var lbl_title = $popup_panel/Control/title_container/lbl_title
@onready var btn_close = $popup_panel/close

# Left Side
@onready var lbl_variety = $popup_panel/margin/hbox/left_side/margin/content/bean/lbl_variety
@onready var lbl_arabica = $popup_panel/margin/hbox/left_side/margin/content/bean/lbl_arabica
@onready var lbl_robusta = $popup_panel/margin/hbox/left_side/margin/content/bean/lbl_robusta
@onready var val_batch = $popup_panel/margin/hbox/left_side/margin/content/batch/value
@onready var radar_graph = $popup_panel/margin/hbox/left_side/margin/content/chart/radar
@onready var cont_cost = get_node_or_null("popup_panel/margin/hbox/left_side/margin/content/cost")
@onready var val_cost = get_node_or_null("popup_panel/margin/hbox/left_side/margin/content/cost/HBoxContainer/value") if has_node("popup_panel/margin/hbox/left_side/margin/content/cost/HBoxContainer/value") else get_node_or_null("popup_panel/margin/hbox/left_side/margin/content/cost/value")

# Right Side
@onready var method_container = $popup_panel/margin/hbox/right_side/margin/method_container
@onready var slider_container = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container
@onready var lbl_level = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container/level_lbl
@onready var slider = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container/slider
@onready var lbl_slider_val = $popup_panel/margin/hbox/right_side/margin/method_container/slider_container/label
@onready var btn_confirm = $popup_panel/margin/hbox/right_side/margin/method_container/confirm


func _ready() -> void:
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	if slider:
		slider.value_changed.connect(_on_slider_changed)
		
	# Hide unused containers if they exist
	if method_container.has_node("process_method"):
		method_container.get_node("process_method").hide()
	if method_container.has_node("option"):
		method_container.get_node("option").hide()

	UIUtils.setup_input_blocker(self)
	hide()

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Roasting":
		current_tile = tile
		current_card_data = card_data
		show_popup()

func show_popup() -> void:
	_reset_ui()
	
	if StageManager.current_location and StageManager.current_location.variety_data:
		var v_data = StageManager.current_location.variety_data
		lbl_variety.text = v_data.variety_name
		lbl_arabica.visible = (v_data.species_name.to_lower() == "arabica")
		lbl_robusta.visible = (v_data.species_name.to_lower() == "robusta")
		
	var cb = StageManager.get_active_farm_batch()
	if cb and val_batch:
		val_batch.text = str(cb.batch_year)
		
	if current_card_data and current_card_data.popup_methods.size() > 0:
		available_methods = current_card_data.popup_methods
		selected_method = available_methods[0]
	
	if slider:
		slider.value = 50.0
		_on_slider_changed(slider.value)
		
	btn_confirm.disabled = false
	show()

func _reset_ui() -> void:
	selected_method = null
	btn_confirm.disabled = true
	
	if val_cost: 
		val_cost.text = "0"
		if val_cost.get_parent() is HBoxContainer:
			val_cost.get_parent().hide()

func _on_slider_changed(val: float) -> void:
	if not selected_method:
		return
		
	if selected_method.slider_levels.size() == 0:
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
	mod_quant_pct = level.mod_quant_pct
	
	if lbl_slider_val:
		lbl_slider_val.text = level.level_name
		
	_update_ui()

func _update_ui() -> void:
	if val_cost and selected_method:
		var c = selected_method.override_cost
		val_cost.text = "%d" % c
		if val_cost.get_parent() is HBoxContainer:
			val_cost.get_parent().visible = (c > 0)
			
	if cont_cost:
		cont_cost.visible = (selected_method != null)

	if radar_graph:
		var cb = StageManager.get_active_farm_batch()
		var b_acid = cb.acidity if cb else 0.0
		var b_aroma = cb.aroma if cb else 0.0
		var b_sweet = cb.sweetness if cb else 0.0
		var b_body = cb.body if cb else 0.0
		var b_flavor = cb.flavor if cb else 0.0
		var b_bitter = cb.bitterness if cb else 0.0
		
		# Base Polygon (Current Stats)
		radar_graph.set_item_value(0, clampf(b_acid, 0.0, 10.0))
		radar_graph.set_item_value(1, clampf(b_aroma, 0.0, 10.0))
		radar_graph.set_item_value(2, clampf(b_sweet, 0.0, 10.0))
		radar_graph.set_item_value(3, clampf(b_body, 0.0, 10.0))
		radar_graph.set_item_value(4, clampf(b_flavor, 0.0, 10.0))
		radar_graph.set_item_value(5, clampf(b_bitter, 0.0, 10.0))
		
		radar_graph.extra_datasets_count = 1
		
		if selected_method:
			# Extra Polygon (Preview Upgrade)
			radar_graph.set_extra_item_value(0, 0, clampf(b_acid + mod_acidity, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 1, clampf(b_aroma + mod_aroma, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 2, clampf(b_sweet + mod_sweetness, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 3, clampf(b_body + mod_body, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 4, clampf(b_flavor + mod_flavor, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 5, clampf(b_bitter + mod_bitterness, 0.0, 10.0))
		else:
			radar_graph.set_extra_item_value(0, 0, 0.0)
			radar_graph.set_extra_item_value(0, 1, 0.0)
			radar_graph.set_extra_item_value(0, 2, 0.0)
			radar_graph.set_extra_item_value(0, 3, 0.0)
			radar_graph.set_extra_item_value(0, 4, 0.0)
			radar_graph.set_extra_item_value(0, 5, 0.0)

func _on_confirm() -> void:
	if selected_method == null:
		return
		
	queue_free()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Roasting", current_tile, current_card_data, {
			"roasting_method": selected_method.method_name,
			"roasting_intensity": slider.value if slider else 50.0,
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
		em.card_placement_interaction_cancelled.emit("Roasting", current_tile, current_card_data)
	current_tile = null
	current_card_data = null

