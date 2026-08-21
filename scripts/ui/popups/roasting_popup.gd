extends CanvasLayer

@onready var hbox_methods = $CenterContainer/PanelContainer/VBox/Split/RightPanel/HBoxMethods
@onready var slider_hbox = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox
@onready var lbl_buds = $CenterContainer/PanelContainer/VBox/Split/RightPanel/LblBuds
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
		
	$CenterContainer/PanelContainer/VBox/Header/LblTitle.text = "ROASTING"
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
		
	for method in available_methods:
		var btn = Button.new()
		btn.text = method.method_name
		btn.custom_minimum_size = Vector2(150, 100)
		btn.pressed.connect(func(): _select_method(method))
		hbox_methods.add_child(btn)

func _select_method(method: ProcessMethodData) -> void:
	if selected_method == method:
		selected_method = null
	else:
		selected_method = method
		
	btn_confirm.disabled = (selected_method == null)
	if selected_method:
		slider_hbox.show()
		val_cost.text = "$%d" % selected_method.override_cost
		lbl_buds.show()
	else:
		slider_hbox.hide()
		lbl_buds.text = "ROASTING LEVEL"
	lbl_buds.show()
	
	for child in hbox_methods.get_children():
		if child is Button:
			child.modulate = Color(0.2, 0.8, 0.2) if (selected_method and child.text == selected_method.method_name) else Color(1.0, 1.0, 1.0)
			
	if not selected_method:
		val_quality.text = "-"
		val_quality.add_theme_color_override("font_color", Color.WHITE)
		val_ripeness.text = "-"
		val_ripeness.add_theme_color_override("font_color", Color.WHITE)
		val_quantity.text = "-"
		val_quantity.add_theme_color_override("font_color", Color.WHITE)
		val_cost.text = "$0"
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
	if card_name == "Roasting":
		current_tile = tile
		current_card_data = card_data
		show_popup()

func show_popup() -> void:
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
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
		if val_surface: val_surface.text = str(StageManager.current_location.surface_area) + " Ha"
	
	timeline_container.hide()
	
	slider_intensity.value = 50.0
	
	if current_card_data and current_card_data.popup_methods.size() > 0:
		available_methods = current_card_data.popup_methods
		selected_method = available_methods[0]
	
	if selected_method:
		val_cost.text = "$%d" % selected_method.override_cost
	
	slider_hbox.show()
	lbl_buds.text = "ROASTING LEVEL"
	lbl_buds.show()
	hbox_methods.get_parent().get_node("LblMethod").hide()
	hbox_methods.hide()
	
	_on_slider_changed(slider_intensity.value)
	
	btn_confirm.disabled = false
	show()

func _update_timeline() -> void:
	var pending_id = ""
	if current_card_data and current_card_data.get("process_id"):
		pending_id = current_card_data.process_id
	UIUtils.build_farm_timeline(timeline_container, 16, 16, 10, 2, pending_id)

func _on_confirm() -> void:
	if selected_method == null:
		return
		
	queue_free()
	if has_node("/root/EventManager") and selected_method != null:
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Roasting", current_tile, current_card_data, {
			"roasting_method": selected_method.method_name,
			"roasting_intensity": slider_intensity.value,
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

	slider_hbox.hide()
	lbl_buds.text = "ROASTING LEVEL"
	lbl_buds.show()
