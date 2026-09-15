extends CanvasLayer

@onready var lbl_title = $CenterContainer/panel/panel_label
@onready var btn_close = $CenterContainer/panel/close

# Left side
@onready var lbl_variety = $CenterContainer/panel/content/bean_name/variety
@onready var lbl_arabica = $CenterContainer/panel/content/bean_name/arabica
@onready var lbl_robusta = $CenterContainer/panel/content/bean_name/robusta
@onready var lbl_batch_value = $CenterContainer/panel/content/bean_detail/left/bean_data/data1/value

@onready var val_cost = $CenterContainer/panel/content/bean_detail/left/cost_turn/cost/HBoxContainer/value
@onready var val_turn = $CenterContainer/panel/content/bean_detail/left/cost_turn/turn/value
@onready var cont_cost = $CenterContainer/panel/content/bean_detail/left/cost_turn/cost/HBoxContainer
@onready var cont_turn = $CenterContainer/panel/content/bean_detail/left/cost_turn/turn/value

# Right side
@onready var radar_graph = $CenterContainer/panel/content/bean_detail/right/chart/radar
@onready var hbox_methods = $CenterContainer/panel/content/bean_detail/left/methods/toggle_buttons
@onready var btn_confirm = $CenterContainer/panel/content/confirmation/confirm

@onready var cont_tools = $CenterContainer/tools
@onready var tools_list = $CenterContainer/tools/content/list/VBoxContainer
@onready var btn_tools_template = $CenterContainer/tools/content/list/VBoxContainer/btn_tools

var method_btn_template: Button

var available_methods: Array[ProcessMethodData] = []
var selected_method: ProcessMethodData
var selected_machine_id: String = ""

var current_tile: Node3D
var current_card_data: Resource

func _ready() -> void:
	if hbox_methods.has_node("opt"):
		method_btn_template = hbox_methods.get_node("opt").duplicate()
		
	btn_tools_template.hide()
	cont_tools.hide()
		
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	UIUtils.setup_input_blocker(self)
	_reset_ui()

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	current_tile = tile
	current_card_data = card_data
	
	var farm_batch = StageManager.get_active_farm_batch()
	
	if card_data.get("popup_methods"):
		available_methods = card_data.popup_methods
		
	if lbl_title:
		lbl_title.text = card_data.card_name
	
	if farm_batch:
		lbl_variety.text = farm_batch.variety_name
		lbl_arabica.visible = (farm_batch.species_name.to_lower() == "arabica")
		lbl_robusta.visible = (farm_batch.species_name.to_lower() == "robusta")
		lbl_batch_value.text = str(farm_batch.batch_year)
	else:
		lbl_variety.text = "Unknown"
		lbl_arabica.visible = false
		lbl_robusta.visible = false
		lbl_batch_value.text = "-"
		
	_build_buttons()
	_update_ui()
	
func _build_buttons() -> void:
	for child in hbox_methods.get_children():
		child.queue_free()
		
	for child in tools_list.get_children():
		if child != btn_tools_template:
			child.queue_free()
		
	if not method_btn_template:
		return
		
	var first_enabled_method = null

	available_methods.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	for method in available_methods:
		var btn = method_btn_template.duplicate()
		var requires_tools = false
		var has_compatible_idle_tool = false
		
		# Validasi apakah method ini diizinkan oleh game rule
		# Misalnya untuk processing, cek apakah batch kita punya nilai cherry_kg yang valid
		var target_batch = StageManager.get_active_farm_batch()
		if target_batch == null or target_batch.cherry_kg == 0:
			btn.disabled = true
			btn.set_pressed_no_signal(false)
		else:
			btn.disabled = false
			if not first_enabled_method:
				first_enabled_method = method
				
		btn.pressed.connect(func(): _select_method(method))
		hbox_methods.add_child(btn)
		btn.show()
		btn.text = method.method_name

	if first_enabled_method:
		_select_method(first_enabled_method)
	else:
		_select_method(null)

func _select_method(method: ProcessMethodData) -> void:
	if selected_method == method:
		selected_method = null
	else:
		selected_method = method
		
	_update_ui()
			
	if not selected_method:
		selected_machine_id = ""
		cont_tools.hide()
		return
	else:
		cont_tools.show()
		_refresh_machine_list()
		
func _refresh_machine_list() -> void:
	for child in tools_list.get_children():
		if child != btn_tools_template:
			child.queue_free()
			
	var target_category = ItemData.ItemCategory.DRYER
	if current_card_data and current_card_data.get("process_id"):
		if current_card_data.process_id.begins_with("RP"):
			target_category = ItemData.ItemCategory.ROASTER
			
	var machines = FactoryManager.get_machines_by_category(target_category)
	
	for m in machines:
		var m_id = m["id"]
		var m_data = m["data"]
		var m_state = m["state"]
		
		var is_compatible = false
		if selected_method and m_data.get("allowed_methods") and selected_method.method_name in m_data.allowed_methods:
			is_compatible = true
			
		if not is_compatible:
			continue
			
		var item = btn_tools_template.duplicate()
		item.show()
		tools_list.add_child(item)
		
		var t_name = item.get_node("content/HBoxContainer/MarginContainer/VBoxContainer/name")
		var t_cap = item.get_node("content/HBoxContainer/MarginContainer/VBoxContainer/capacity")
		var t_avail = item.get_node("content/HBoxContainer/MarginContainer/VBoxContainer/use/available")
		var t_dash = item.get_node("content/HBoxContainer/MarginContainer/VBoxContainer/use/-")
		var t_batch = item.get_node("content/HBoxContainer/MarginContainer/VBoxContainer/use/batch")
		
		t_name.text = m_data.item_name
		t_cap.text = "%d Kg" % m_data.max_capacity
		
		item.toggle_mode = true
		
		if m_state == "USED":
			t_avail.text = "In Use"
			t_dash.show()
			t_batch.show()
			if m.has("batch_name"):
				t_batch.text = m["batch_name"]
			else:
				t_batch.text = ""
			item.disabled = true
			item.button_pressed = false
		else:
			t_avail.text = "Idle"
			t_dash.hide()
			t_batch.hide()
			
			if selected_machine_id == m_id:
				item.button_pressed = true
			else:
				item.button_pressed = false
				
		item.toggled.connect(func(is_pressed: bool):
			if is_pressed:
				selected_machine_id = m_id
			else:
				if selected_machine_id == m_id:
					selected_machine_id = ""
			_refresh_machine_list()
			_update_ui()
		)

func _update_ui() -> void:
	btn_confirm.disabled = (selected_method == null or selected_machine_id == "")
	
	for child in hbox_methods.get_children():
		if child is Button:
			child.toggle_mode = true
			child.set_pressed_no_signal(selected_method and child.text == selected_method.method_name)
				
	if val_cost and val_turn:
		var c = 0
		var t = 0
		if selected_method:
			c += selected_method.override_cost
			var eff = 1.0
			if selected_machine_id != "" and FactoryManager.placed_machines.has(selected_machine_id):
				eff = FactoryManager.placed_machines[selected_machine_id]["data"].efficiency_multiplier
			t += int(ceil(selected_method.turn_duration / eff))
			
		val_cost.text = "%d" % c
		val_turn.text = "%d" % t
		
		if val_cost:
			val_cost.visible = true
		if val_turn:
			val_turn.visible = true
			
		if cont_cost:
			cont_cost.visible = (selected_method != null)
		if cont_turn:
			cont_turn.visible = (selected_method != null)

	if radar_graph:
		var cb = StageManager.get_active_farm_batch()
		var b_acid = cb.acidity if cb else 0.0
		var b_aroma = cb.aroma if cb else 0.0
		var b_sweet = cb.sweetness if cb else 0.0
		var b_body = cb.body if cb else 0.0
		var b_flavor = cb.flavor if cb else 0.0
		var b_bitter = cb.bitterness if cb else 0.0
		
		# Set the base values (Stat Murni) on polygon 0 (Main Polygon)
		radar_graph.set_item_value(0, clampf(b_acid, 0.0, 10.0))
		radar_graph.set_item_value(1, clampf(b_aroma, 0.0, 10.0))
		radar_graph.set_item_value(2, clampf(b_sweet, 0.0, 10.0))
		radar_graph.set_item_value(3, clampf(b_body, 0.0, 10.0))
		radar_graph.set_item_value(4, clampf(b_flavor, 0.0, 10.0))
		radar_graph.set_item_value(5, clampf(b_bitter, 0.0, 10.0))
		
		radar_graph.extra_datasets_count = 1
		
		if selected_method:
			var m_a = selected_method.mod_acidity
			var m_ar = selected_method.mod_aroma
			var m_sw = selected_method.mod_sweetness
			var m_bd = selected_method.mod_body
			var m_f = selected_method.mod_flavor
			var m_bt = selected_method.mod_bitterness
				
			# Set the preview values on polygon 1 (Extra Polygon 0)
			radar_graph.set_extra_item_value(0, 0, clampf(b_acid + m_a, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 1, clampf(b_aroma + m_ar, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 2, clampf(b_sweet + m_sw, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 3, clampf(b_body + m_bd, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 4, clampf(b_flavor + m_f, 0.0, 10.0))
			radar_graph.set_extra_item_value(0, 5, clampf(b_bitter + m_bt, 0.0, 10.0))
		else:
			# Hide the preview if nothing selected
			radar_graph.set_extra_item_value(0, 0, 0.0)
			radar_graph.set_extra_item_value(0, 1, 0.0)
			radar_graph.set_extra_item_value(0, 2, 0.0)
			radar_graph.set_extra_item_value(0, 3, 0.0)
			radar_graph.set_extra_item_value(0, 4, 0.0)
			radar_graph.set_extra_item_value(0, 5, 0.0)

func _on_confirm() -> void:
	queue_free()
	if not selected_method or selected_machine_id == "": return
		
	var machine_id = selected_machine_id
	FactoryManager.placed_machines[machine_id]["state"] = "USED"
	
	# Simpan nama batch agar nanti "In Use - Batch Name" bisa muncul
	var farm_batch = StageManager.get_active_farm_batch()
	if farm_batch:
		FactoryManager.placed_machines[machine_id]["batch_name"] = farm_batch.variety_name + " " + str(farm_batch.batch_year)
	
	var machine_data = FactoryManager.placed_machines[machine_id]["data"]

	var extra_data = {
		"process_method": selected_method.method_name,
		"drying_tool": machine_data.item_name,
		"machine_id": machine_id,
		"override_cost": selected_method.override_cost,
		"turn_duration": int(ceil(selected_method.turn_duration / machine_data.efficiency_multiplier)),
		"mod_acidity": selected_method.mod_acidity,
		"mod_aroma": selected_method.mod_aroma,
		"mod_sweetness": selected_method.mod_sweetness,
		"mod_flavor": selected_method.mod_flavor,
		"mod_body": selected_method.mod_body,
		"mod_bitterness": selected_method.mod_bitterness,
		"mod_defect": selected_method.mod_defect,
		"mod_quant_pct": selected_method.mod_quant_pct
	}
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Process", current_tile, current_card_data, extra_data)
		
	current_tile = null
	current_card_data = null

func _on_cancel() -> void:
	queue_free()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Process", current_tile, current_card_data)
	current_tile = null
	current_card_data = null

func _reset_ui() -> void:
	selected_method = null
	selected_machine_id = ""
	btn_confirm.disabled = true
	
	if val_cost and val_turn:
		var c = 0
		var t = 0
		if selected_method:
			c += selected_method.override_cost
			t += selected_method.turn_duration
			
		val_cost.text = "%d" % c
		val_turn.text = "%d" % t
		
		# Hide if 0
		if val_cost:
			val_cost.visible = (c > 0)
		if cont_turn:
			cont_turn.visible = (t > 0)

	if radar_graph:
		_update_ui() # this will handle showing base stats if no method is selected
			
	for child in hbox_methods.get_children():
		if child is Button:
			child.set_pressed_no_signal(false)
