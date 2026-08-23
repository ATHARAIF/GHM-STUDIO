extends CanvasLayer

@onready var lbl_title = $popup_panel/Control/title_container/lbl_title
@onready var btn_info = $popup_panel/Control/title_container/info_button
@onready var btn_close = $popup_panel/close

# Left side

@onready var lbl_variety = $popup_panel/margin/hbox/left_side/margin/content/bean/lbl_variety
@onready var lbl_arabica = $popup_panel/margin/hbox/left_side/margin/content/bean/lbl_arabica
@onready var lbl_robusta = $popup_panel/margin/hbox/left_side/margin/content/bean/lbl_robusta
@onready var lbl_batch_value = $popup_panel/margin/hbox/left_side/margin/content/batch/value
@onready var radar_graph = $popup_panel/margin/hbox/left_side/margin/content/chart/radar
@onready var val_cost = $popup_panel/margin/hbox/left_side/margin/content/VBoxContainer/cost/HBoxContainer/value
@onready var val_turn = $popup_panel/margin/hbox/left_side/margin/content/VBoxContainer/turn/value
@onready var cont_cost = $popup_panel/margin/hbox/left_side/margin/content/VBoxContainer/cost/HBoxContainer
@onready var cont_turn = $popup_panel/margin/hbox/left_side/margin/content/VBoxContainer/turn/value

# Right side
@onready var hbox_methods = $popup_panel/margin/hbox/right_side/margin/method_container/option
@onready var hbox_tools = $popup_panel/margin/hbox/right_side/margin/method_container/option2
@onready var btn_confirm = $popup_panel/margin/hbox/right_side/margin/method_container/confirm

var method_btn_template: Button
var tool_btn_template: Button

var available_methods: Array[ProcessMethodData] = []
var available_tools: Array[ProcessMethodData] = []
var selected_method: ProcessMethodData
var selected_tool: ProcessMethodData

var current_tile: Node3D
var current_card_data: Resource

func _ready() -> void:
	if hbox_methods.has_node("opt"):
		method_btn_template = hbox_methods.get_node("opt").duplicate()
	if hbox_tools.has_node("opt"):
		tool_btn_template = hbox_tools.get_node("opt").duplicate()
		
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)

	UIUtils.setup_input_blocker(self)
	hide()

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Processing":
		current_tile = tile
		current_card_data = card_data
		
		if StageManager.current_location and StageManager.current_location.variety_data:
			var v_data = StageManager.current_location.variety_data
			if lbl_variety: lbl_variety.text = v_data.variety_name
			if lbl_arabica and lbl_robusta:
				if v_data.species_name.to_lower() == "arabica":
					lbl_arabica.show()
					lbl_robusta.hide()
				else:
					lbl_arabica.hide()
					lbl_robusta.show()
					
		if lbl_batch_value:
			lbl_batch_value.text = str(TimeManager.year)
			
		if current_card_data:
			if current_card_data.get("popup_methods"):
				available_methods = current_card_data.popup_methods
			else:
				available_methods = []
			if current_card_data.get("popup_tools"):
				available_tools = current_card_data.popup_tools
			else:
				available_tools = []
				
		_build_buttons()
		_reset_ui()
		show()

func _build_buttons() -> void:
	for child in hbox_methods.get_children():
		child.queue_free()
	for child in hbox_tools.get_children():
		child.queue_free()
		
	if not method_btn_template or not tool_btn_template:
		return
		
	available_methods.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	for method in available_methods:
		var btn = method_btn_template.duplicate()
		btn.show()
		btn.text = method.method_name
		btn.pressed.connect(func(): _select_method(method))
		hbox_methods.add_child(btn)

	available_tools.sort_custom(func(a, b): return a.sort_order < b.sort_order)
	for tool in available_tools:
		var btn = tool_btn_template.duplicate()
		btn.show()
		btn.text = tool.method_name
		btn.pressed.connect(func(): _select_tool(tool))
		hbox_tools.add_child(btn)

	if available_methods.size() > 0: _select_method(available_methods[0])
	if available_tools.size() > 0: _select_tool(available_tools[0])

func _select_method(method: ProcessMethodData) -> void:
	if selected_method == method:
		selected_method = null
	else:
		selected_method = method
		
	_update_ui()
			
	if not selected_method:
		selected_tool = null
		for child in hbox_tools.get_children():
			if child is Button:
				child.disabled = true
				child.set_pressed_no_signal(false)
		return
			
	var first_compatible = null
	var is_current_tool_compatible = false
	
	for child in hbox_tools.get_children():
		if child is Button:
			var tool_data = null
			for t in available_tools:
				if t.method_name == child.text:
					tool_data = t
					break
			
			if tool_data:
				var is_compatible = true
				if tool_data.allowed_methods.size() > 0 and (not selected_method or not selected_method.method_name in tool_data.allowed_methods):
					is_compatible = false
					
				child.disabled = not is_compatible
				
				if is_compatible:
					if not first_compatible:
						first_compatible = tool_data
					if selected_tool and selected_tool.method_name == tool_data.method_name:
						is_current_tool_compatible = true
						
	if not is_current_tool_compatible and first_compatible:
		_select_tool(first_compatible)

func _select_tool(tool: ProcessMethodData) -> void:
	if selected_tool == tool:
		# Kembalikan state visual button karena Godot otomatis untoggle
		for child in hbox_tools.get_children():
			if child is Button and child.text == tool.method_name:
				child.set_pressed_no_signal(true)
		return
	else:
		selected_tool = tool
	_update_ui()

func _update_ui() -> void:
	btn_confirm.disabled = (selected_method == null or selected_tool == null)
	
	for child in hbox_methods.get_children():
		if child is Button:
			child.toggle_mode = true
			child.set_pressed_no_signal(selected_method and child.text == selected_method.method_name)
				
	for child in hbox_tools.get_children():
		if child is Button:
			child.toggle_mode = true
			child.set_pressed_no_signal(selected_tool and child.text == selected_tool.method_name)
				
	if val_cost and val_turn:
		var c = 0
		var t = 0
		if selected_method:
			c += selected_method.override_cost
			t += selected_method.turn_duration
		if selected_tool:
			c += selected_tool.override_cost
			t += selected_tool.turn_duration
			
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
			
			if selected_tool:
				m_a += selected_tool.mod_acidity
				m_ar += selected_tool.mod_aroma
				m_sw += selected_tool.mod_sweetness
				m_bd += selected_tool.mod_body
				m_f += selected_tool.mod_flavor
				m_bt += selected_tool.mod_bitterness
				
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
	hide()
	if not selected_method or not selected_tool: return
		
	var extra_data = {
		"process_method": selected_method.method_name,
		"drying_tool": selected_tool.method_name,
		"override_cost": selected_method.override_cost + selected_tool.override_cost,
		"turn_duration": selected_method.turn_duration + selected_tool.turn_duration,
		"mod_acidity": selected_method.mod_acidity + selected_tool.mod_acidity,
		"mod_aroma": selected_method.mod_aroma + selected_tool.mod_aroma,
		"mod_sweetness": selected_method.mod_sweetness + selected_tool.mod_sweetness,
		"mod_flavor": selected_method.mod_flavor + selected_tool.mod_flavor,
		"mod_body": selected_method.mod_body + selected_tool.mod_body,
		"mod_bitterness": selected_method.mod_bitterness + selected_tool.mod_bitterness,
		"mod_defect": selected_method.mod_defect + selected_tool.mod_defect,
		"mod_quant_pct": selected_method.mod_quant_pct + selected_tool.mod_quant_pct
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
	selected_tool = null
	btn_confirm.disabled = true
	
	if val_cost and val_turn:
		var c = 0
		var t = 0
		if selected_method:
			c += selected_method.override_cost
			t += selected_method.turn_duration
		if selected_tool:
			c += selected_tool.override_cost
			t += selected_tool.turn_duration
			
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

	for child in hbox_tools.get_children():
		if child is Button:
			child.disabled = true
			child.set_pressed_no_signal(false)
