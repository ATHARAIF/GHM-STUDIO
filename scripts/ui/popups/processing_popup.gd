extends CanvasLayer

@onready var hbox_methods = $CenterContainer/PanelContainer/VBox/Split/RightPanel/HBoxMethods
var hbox_tools: HBoxContainer
@onready var btn_confirm = $CenterContainer/PanelContainer/VBox/Split/RightPanel/BtnConfirm
@onready var btn_close = $CenterContainer/PanelContainer/VBox/Header/BtnClose

@onready var val_ripeness = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VRip
@onready var val_quality = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQual
@onready var val_quantity = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQuant

@onready var lbl_farm_name = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/LblFarmName
@onready var val_surface = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid/VSurface
@onready var val_plant = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid/VPlant
var val_turn: Label
@onready var timeline_container = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Timeline

var available_methods: Array[ProcessMethodData] = []
var available_tools: Array[ProcessMethodData] = []

var selected_method: ProcessMethodData
var val_cost: Label
var selected_tool: ProcessMethodData

var current_tile: Node3D
var current_card_data: Resource

func _ready() -> void:
	var grid2 = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2
	grid2.show()
	if not grid2.has_node("LCost"):
		var lcost = Label.new()
		lcost.name = "LCost"
		lcost.text = "Cost"
		lcost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid2.add_child(lcost)
		grid2.move_child(lcost, 0)
		
		val_cost = Label.new()
		val_cost.name = "VCost"
		val_cost.text = "$0"
		val_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid2.add_child(val_cost)
		grid2.move_child(val_cost, 1)

		var lturn = Label.new()
		lturn.name = "LTurn"
		lturn.text = "Turn"
		lturn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid2.add_child(lturn)
		grid2.move_child(lturn, 2)
		
		val_turn = Label.new()
		val_turn.name = "VTurn"
		val_turn.text = "0"
		val_turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid2.add_child(val_turn)
		grid2.move_child(val_turn, 3)
	else:
		val_cost = grid2.get_node("VCost")
		val_turn = grid2.get_node("VTurn")

	# Hide Ripeness, Quality, and Quantity for processing
	for child in grid2.get_children():
		if child.name not in ["LCost", "VCost", "LTurn", "VTurn"]:
			child.hide()


		
	$CenterContainer/PanelContainer/VBox/Header/LblTitle.text = "COFFEE PROCESSING"
	$CenterContainer/PanelContainer/VBox/Split/RightPanel/LblMethod.text = "Select Processing Method:"
	
	# Create label and hbox for tools dynamically if they don't exist yet
	var lbl_tool = Label.new()
	lbl_tool.text = "Select Drying Tool:"
	lbl_tool.add_theme_font_size_override("font_size", 18)
	
	if not $CenterContainer/PanelContainer/VBox/Split/RightPanel.has_node("HBoxTools"):
		hbox_tools = HBoxContainer.new()
		hbox_tools.name = "HBoxTools"
		var parent = $CenterContainer/PanelContainer/VBox/Split/RightPanel
		parent.add_child(lbl_tool)
		parent.add_child(hbox_tools)
		parent.move_child(lbl_tool, 2)
		parent.move_child(hbox_tools, 3)
		# Move confirm button to bottom
		parent.move_child(btn_confirm, parent.get_child_count() - 1)
	else:
		hbox_tools = $CenterContainer/PanelContainer/VBox/Split/RightPanel.get_node("HBoxTools")
	

	$CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox.hide() 
	
	_build_buttons()
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)

	
	
	UIUtils.setup_input_blocker(self)
	hide()

func _build_buttons() -> void:
	for child in hbox_methods.get_children(): child.queue_free()
	for method in available_methods:
		var btn = Button.new()
		btn.text = method.method_name
		btn.custom_minimum_size = Vector2(150, 80)
		btn.pressed.connect(func(): _select_method(method))
		hbox_methods.add_child(btn)

	for child in hbox_tools.get_children(): child.queue_free()
	for tool in available_tools:
		var btn = Button.new()
		btn.text = tool.method_name
		btn.custom_minimum_size = Vector2(150, 80)
		btn.pressed.connect(func(): _select_tool(tool))
		hbox_tools.add_child(btn)

	if available_methods.size() > 0: _select_method(available_methods[0])
	if available_tools.size() > 0: _select_tool(available_tools[0])

func _select_method(method: ProcessMethodData) -> void:
	if selected_method == method:
		selected_method = null
	else:
		selected_method = method
		
	for child in hbox_methods.get_children():
		if child is Button:
			child.modulate = Color(0.2, 0.8, 0.2) if (selected_method and child.text == selected_method.method_name) else Color(1, 1, 1)
			
	if not selected_method:
		selected_tool = null
		for child in hbox_tools.get_children():
			if child is Button:
				child.disabled = true
				child.modulate = Color(1, 1, 1)
		_update_totals()
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
	else:
		_update_totals()

func _select_tool(tool: ProcessMethodData) -> void:
	if selected_tool == tool:
		selected_tool = null
	else:
		selected_tool = tool
	for child in hbox_tools.get_children():
		if child is Button:
			child.modulate = Color(0.2, 0.8, 0.2) if (selected_tool and child.text == selected_tool.method_name) else Color(1, 1, 1)
	_update_totals()

func _update_totals() -> void:
	btn_confirm.disabled = (selected_method == null or selected_tool == null)
	if not selected_method or not selected_tool:
		val_cost.text = "$0"
		if val_turn: val_turn.text = "0"
		return
	
	var total_cost = selected_method.override_cost + selected_tool.override_cost
	var total_turn = selected_method.turn_duration + selected_tool.turn_duration
	
	val_cost.text = "$%d" % total_cost
	if val_turn:
		val_turn.text = "%d" % total_turn

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Processing":
		current_tile = tile
		current_card_data = card_data
		if StageManager.current_location:
			lbl_farm_name.text = StageManager.current_location.location_name
			if val_surface: val_surface.text = str(StageManager.current_location.surface_area) + " Ha"
			if StageManager.current_location.variety_data:
				val_plant.text = StageManager.current_location.variety_data.species_name
			
			# Tambah row Variety secara dinamis jika belum ada
			var grid = val_plant.get_parent()
			if not grid.has_node("LVariety"):
				# Cari node LPlant dan ubah namanya jadi Species
				var lplant = grid.get_node("LPlant")
				if lplant:
					lplant.text = "Species"
					
				var lvar = Label.new()
				lvar.name = "LVariety"
				lvar.text = "Variety"
				lvar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(lvar)
				
				var vvar = Label.new()
				vvar.name = "VVariety"
				vvar.text = StageManager.current_location.variety_data.variety_name
				vvar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				grid.add_child(vvar)
			else:
				var vvar = grid.get_node("VVariety")
				vvar.text = StageManager.current_location.variety_data.variety_name
		available_methods = card_data.popup_methods
		available_tools = card_data.popup_tools
		_build_buttons()
		_reset_ui()
		show()

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
	btn_confirm.disabled = true
	
	if val_cost: val_cost.text = "$0"
	if val_quality:
		val_quality.text = "-"
		val_quality.modulate = Color.WHITE
		if val_quality.has_theme_color_override("font_color"):
			val_quality.add_theme_color_override("font_color", Color.WHITE)
	if val_ripeness:
		val_ripeness.text = "-"
		val_ripeness.modulate = Color.WHITE
		if val_ripeness.has_theme_color_override("font_color"):
			val_ripeness.add_theme_color_override("font_color", Color.WHITE)
	if val_quantity:
		val_quantity.text = "-"
		val_quantity.modulate = Color.WHITE
		if val_quantity.has_theme_color_override("font_color"):
			val_quantity.add_theme_color_override("font_color", Color.WHITE)
			
	for child in hbox_methods.get_children():
		if child is Button:
			child.modulate = Color(1.0, 1.0, 1.0)

	selected_tool = null
	for child in hbox_tools.get_children():
		if child is Button:
			child.disabled = true
			child.modulate = Color(1.0, 1.0, 1.0)
	if val_turn: val_turn.text = "0"
