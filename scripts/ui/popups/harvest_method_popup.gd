extends CanvasLayer

@onready var hbox_methods = $CenterContainer/PanelContainer/VBox/Split/RightPanel/HBoxMethods
@onready var slider_intensity = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/SliderIntensity
@onready var lbl_intensity_val = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/LblIntensityVal

@onready var btn_confirm = $popup_panel/margin/hbox/right_side/margin/content/confirm
@onready var btn_close = $popup_panel/close

@onready var val_ripeness = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VRip
@onready var val_quality = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQual
@onready var val_quantity = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQuant

@onready var lbl_farm_name = $popup_panel/margin/hbox/left_side/margin/content/terroir/lbl_terroir
@onready var val_plant = $popup_panel/margin/hbox/left_side/margin/content/plant/value
@onready var timeline_container = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Timeline

var available_methods: Array[ProcessMethodData] = []
var selected_method: ProcessMethodData

var current_tile: Node3D
var current_card_data: Resource

func _ready() -> void:
	$CenterContainer/PanelContainer/VBox/Header/LblTitle.text = "HARVEST METHOD"
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
	
	$CenterContainer/PanelContainer/VBox/Split/RightPanel/LblMethod.text = "Select Harvesting Method:"
	$CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox.hide() # Hide intensity slider
	
	_load_methods()
	_build_method_buttons()
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(_on_card_placement_interaction_requested)
	
	UIUtils.setup_input_blocker(self)
	hide()

func _load_methods() -> void:
	var path = "res://resources/methods/harvest/"
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
		
	if available_methods.size() > 0:
		_select_method(available_methods[0])

func _select_method(method: ProcessMethodData) -> void:
	selected_method = method
	
	for child in hbox_methods.get_children():
		if child is Button:
			if child.text == method.method_name:
				child.modulate = Color(0.2, 0.8, 0.2)
			else:
				child.modulate = Color(1, 1, 1)
	
	val_quality.text = method.ui_qual_text
	val_quality.modulate = method.ui_qual_color
	val_ripeness.text = method.ui_rip_text
	val_ripeness.modulate = method.ui_rip_color
	val_quantity.text = method.ui_quant_text
	val_quantity.modulate = method.ui_quant_color
	
	val_plant.text = "$%d" % method.override_cost
	$CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid/LPlant.text = "Cost:"

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_data.interaction_type == "HARVEST":
		current_tile = tile
		current_card_data = card_data
		
		if StageManager.current_location:
			lbl_farm_name.text = StageManager.current_location.location_name
		
		_update_timeline()
		show()

func _update_timeline() -> void:
	var pending_id = ""
	if current_card_data and current_card_data.get("process_id"):
		pending_id = current_card_data.process_id
	UIUtils.build_farm_timeline(timeline_container, 16, 16, 10, 2, pending_id)

func _on_confirm() -> void:
	hide()
	
	if selected_method == null:
		return
		
	var extra_data = {
		"harvest_method": selected_method.method_name,
		"override_cost": selected_method.override_cost,
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
		em.card_placement_interaction_confirmed.emit("Harvest", current_tile, current_card_data, extra_data)
		
	current_tile = null
	current_card_data = null

func _on_cancel() -> void:
	hide()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Harvest", current_tile, current_card_data)
	current_tile = null
	current_card_data = null
