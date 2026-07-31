extends CanvasLayer

@onready var btn_single = $CenterContainer/PanelContainer/VBox/Split/RightPanel/HBoxMethods/BtnSingle
@onready var btn_multi = $CenterContainer/PanelContainer/VBox/Split/RightPanel/HBoxMethods/BtnMulti
@onready var slider_intensity = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/SliderIntensity
@onready var lbl_intensity_val = $CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox/LblIntensityVal

@onready var btn_confirm = $CenterContainer/PanelContainer/VBox/Split/RightPanel/BtnConfirm
@onready var btn_close = $CenterContainer/PanelContainer/VBox/Header/BtnClose

@onready var val_ripeness = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VRip
@onready var val_quality = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQual
@onready var val_quantity = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid2/VQuant

@onready var lbl_farm_name = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/LblFarmName
@onready var val_plant = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Grid/VPlant
@onready var timeline_container = $CenterContainer/PanelContainer/VBox/Split/LeftPanel/Margin/VBox/Timeline

var selected_method: String = "Single-Stem"

# Store modifiers to pass them later
var mod_acidity: float = 0.0
var mod_aroma: float = 0.0
var mod_sweetness: float = 0.0
var mod_flavor: float = 0.0
var mod_body: float = 0.0
var mod_bitterness: float = 0.0
var mod_quant_pct: float = 0.0

func _ready() -> void:
	btn_single.pressed.connect(func(): _select_method("Single-Stem"))
	btn_multi.pressed.connect(func(): _select_method("Multi-Stem"))
	
	slider_intensity.value_changed.connect(_on_slider_changed)
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(_on_card_placement_interaction_requested)
	
	UIUtils.setup_input_blocker(self)
	
	_select_method("Single-Stem")
	_on_slider_changed(slider_intensity.value)
	
	hide()

func _select_method(method: String) -> void:
	selected_method = method
	if method == "Single-Stem":
		btn_single.modulate = Color(0.2, 0.8, 0.2)
		btn_multi.modulate = Color(1.0, 1.0, 1.0)
	else:
		btn_single.modulate = Color(1.0, 1.0, 1.0)
		btn_multi.modulate = Color(0.2, 0.8, 0.2)

func _on_slider_changed(val: float) -> void:
	var text = "Medium"
	var rip_text = "+"
	var qual_text = "++"
	var quant_text = ""
	
	var rip_color = Color(0.2, 0.6, 1.0)
	var qual_color = Color(0.2, 0.6, 1.0)
	var quant_color = Color.WHITE
	
	if val <= 0:
		text = "Very Low"
		qual_text = "++++"; qual_color = Color(0.2, 0.8, 0.2)
		rip_text = "+++"; rip_color = Color(0.2, 0.8, 0.2)
		quant_text = "--"; quant_color = Color(0.8, 0.2, 0.2)
		mod_acidity = 0.50; mod_aroma = 0.50; mod_sweetness = 0.50; mod_flavor = 0.50; mod_body = 0.0; mod_bitterness = 0.0; mod_quant_pct = -0.2
	elif val <= 25:
		text = "Low"
		qual_text = "+++"; qual_color = Color(0.2, 0.8, 0.2)
		rip_text = "++"; rip_color = Color(0.2, 0.8, 0.2)
		quant_text = "-"; quant_color = Color(0.8, 0.2, 0.2)
		mod_acidity = 0.35; mod_aroma = 0.35; mod_sweetness = 0.35; mod_flavor = 0.35; mod_body = 0.0; mod_bitterness = 0.0; mod_quant_pct = -0.1
	elif val <= 50:
		text = "Medium"
		qual_text = "++"; qual_color = Color(0.2, 0.6, 1.0)
		rip_text = "+"; rip_color = Color(0.2, 0.6, 1.0)
		quant_text = ""; quant_color = Color.WHITE
		mod_acidity = 0.20; mod_aroma = 0.20; mod_sweetness = 0.20; mod_flavor = 0.20; mod_body = 0.0; mod_bitterness = 0.0; mod_quant_pct = 0.0
	elif val <= 75:
		text = "High"
		qual_text = "-"; qual_color = Color(0.8, 0.2, 0.2)
		rip_text = "--"; rip_color = Color(0.8, 0.2, 0.2)
		quant_text = "+++"; quant_color = Color(0.2, 0.6, 1.0)
		mod_acidity = -0.20; mod_aroma = -0.20; mod_sweetness = -0.20; mod_flavor = -0.20; mod_body = 0.0; mod_bitterness = 0.0; mod_quant_pct = 0.3
	else:
		text = "Very High"
		qual_text = "--"; qual_color = Color(0.8, 0.2, 0.2)
		rip_text = "---"; rip_color = Color(0.8, 0.2, 0.2)
		quant_text = "++++"; quant_color = Color(1.0, 1.0, 0.0)
		mod_acidity = -0.35; mod_aroma = -0.35; mod_sweetness = -0.35; mod_flavor = -0.35; mod_body = 0.0; mod_bitterness = 0.0; mod_quant_pct = 0.4
	
	lbl_intensity_val.text = text
	
	val_ripeness.text = rip_text
	val_ripeness.add_theme_color_override("font_color", rip_color)
	
	val_quality.text = qual_text
	val_quality.add_theme_color_override("font_color", qual_color)
	
	val_quantity.text = quant_text
	val_quantity.add_theme_color_override("font_color", quant_color)

var current_tile: Node3D
var current_card_data: Resource

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Pruning":
		current_tile = tile
		current_card_data = card_data
		show_popup()

func show_popup() -> void:
	# Update texts
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
		# Assuming we just set plant variety hardcoded as Kintamani for now based on user feedback
		val_plant.text = "Kintamani"
	
	_update_timeline()
	
	# Reset state if needed
	_select_method("Single-Stem")
	slider_intensity.value = 50.0
	show()

func _update_timeline() -> void:
	UIUtils.build_farm_timeline(timeline_container, 16, 16, 10, 2)

func _on_confirm() -> void:
	hide()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Pruning", current_tile, current_card_data, {
			"pruning_method": selected_method,
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
