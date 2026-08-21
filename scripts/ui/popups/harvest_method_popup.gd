extends CanvasLayer

@onready var hbox_methods = $CenterContainer/PanelContainer/VBox/Split/RightPanel/HBoxMethods
@onready var slider_intensity = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/SliderIntensity
@onready var lbl_intensity_val = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/LblIntensityVal

@onready var btn_confirm = $CenterContainer/PanelContainer/VBox/Split/RightPanel/BtnConfirm
@onready var btn_close = $CenterContainer/PanelContainer/VBox/Header/BtnClose

@onready var val_ripeness = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VRip
@onready var val_quality = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQual
@onready var val_quantity = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQuant

@onready var lbl_farm_name = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/LblFarmName
@onready var val_surface = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid/VSurface
@onready var val_plant = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid/VPlant
@onready var timeline_container = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Timeline

var available_methods: Array[ProcessMethodData] = []
var selected_method: ProcessMethodData
var val_cost: Label

var current_tile: Node3D
var current_card_data: Resource

func _ready() -> void:
	var grid2 = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2
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
	else:
		val_cost = grid2.get_node("VCost")
		
	$CenterContainer/PanelContainer/VBox/Header/LblTitle.text = "HARVEST METHOD"
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
	
	$CenterContainer/PanelContainer/VBox/Split/RightPanel/LblMethod.text = "Select Harvesting Method:"
	$CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox.hide() # Hide intensity slider
	
	_build_method_buttons()
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)


	
	
	UIUtils.setup_input_blocker(self)
	hide()

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
	if selected_method == method:
		selected_method = null
	else:
		selected_method = method
		
	btn_confirm.disabled = (selected_method == null)
	
	for child in hbox_methods.get_children():
		if child is Button:
			child.modulate = Color(0.2, 0.8, 0.2) if (selected_method and child.text == selected_method.method_name) else Color(1, 1, 1)
	
	if selected_method:
		val_quality.text = selected_method.ui_qual_text
		val_quality.modulate = selected_method.ui_qual_color
		val_ripeness.text = selected_method.ui_rip_text
		val_ripeness.modulate = selected_method.ui_rip_color
		val_quantity.text = selected_method.ui_quant_text
		val_quantity.modulate = selected_method.ui_quant_color
		val_cost.text = "$%d" % selected_method.override_cost
	else:
		val_quality.text = "-"
		val_quality.modulate = Color.WHITE
		val_ripeness.text = "-"
		val_ripeness.modulate = Color.WHITE
		val_quantity.text = "-"
		val_quantity.modulate = Color.WHITE
		val_cost.text = "$0"
func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Harvest":
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
		
		_update_timeline()
		available_methods = card_data.popup_methods
		_build_method_buttons()
		_reset_ui()
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
	queue_free()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Harvest", current_tile, current_card_data)
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
