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

var selected_method: String = "Selective"

var mod_acidity: float = 0.0
var mod_aroma: float = 0.0
var mod_sweetness: float = 0.0
var mod_flavor: float = 0.0
var mod_body: float = 0.0
var mod_bitterness: float = 0.0
var mod_defect: float = 0.0
var override_cost: int = 0
var mod_quant_pct: float = 0.0

var current_tile: Node3D
var current_card_data: Resource



func _ready() -> void:
	# Rename labels and headers
	$CenterContainer/PanelContainer/VBox/Header/LblTitle.text = "HARVEST METHOD"
	if StageManager.current_location:
		lbl_farm_name.text = StageManager.current_location.location_name
	
	$CenterContainer/PanelContainer/VBox/Split/RightPanel/LblMethod.text = "Select Harvesting Method:"
	$CenterContainer/PanelContainer/VBox/Split/RightPanel/SliderHBox.hide() # Hide intensity slider
	
	btn_single.text = "Strip Picking"
	btn_multi.text = "Selective Picking"
	
	btn_single.pressed.connect(_on_method_selected.bind("Strip"))
	btn_multi.pressed.connect(_on_method_selected.bind("Selective"))
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(_on_card_placement_interaction_requested)
	
	UIUtils.setup_input_blocker(self)
		
	_select_method("Selective")
	hide()

func _on_method_selected(method_name: String) -> void:
	_select_method(method_name)

func _select_method(method_name: String) -> void:
	selected_method = method_name
	
	btn_single.modulate = Color(1, 1, 1)
	btn_multi.modulate = Color(1, 1, 1)
	
	mod_acidity = 0.0
	mod_aroma = 0.0
	mod_sweetness = 0.0
	mod_flavor = 0.0
	mod_body = 0.0
	mod_bitterness = 0.0
	mod_defect = 0.0
	mod_quant_pct = 0.0
	
	var qual_text = ""
	var qual_color = Color.WHITE
	var rip_text = ""
	var rip_color = Color.WHITE
	var quant_text = ""
	var quant_color = Color.WHITE
	
	if method_name == "Strip":
		btn_single.modulate = Color(0.2, 0.8, 0.2)
		override_cost = 500
		
		# Quality Turun
		mod_acidity = -0.2
		mod_sweetness = -0.2
		mod_flavor = -0.2
		mod_defect = 5.0
		qual_text = "-"
		qual_color = Color(0.8, 0.4, 0.4)
		
		# Ripeness Acak (Fair)
		rip_text = "Mixed"
		rip_color = Color(0.8, 0.8, 0.4)
		
		# Yield Normal
		mod_quant_pct = 0.0
		quant_text = "100%"
		quant_color = Color.WHITE
		
	elif method_name == "Selective":
		btn_multi.modulate = Color(0.2, 0.8, 0.2)
		override_cost = 800
		
		# Quality Sangat Baik
		mod_acidity = 0.3
		mod_sweetness = 0.3
		mod_flavor = 0.3
		mod_defect = -5.0
		qual_text = "++"
		qual_color = Color(0.4, 0.8, 0.4)
		
		# Ripeness Sempurna
		rip_text = "Perfect"
		rip_color = Color(0.4, 0.8, 0.4)
		
		# Yield Turun (hanya petik yang matang)
		mod_quant_pct = -0.15 # -15%
		quant_text = "85%"
		quant_color = Color(0.8, 0.4, 0.4)
		

		
	val_quality.text = qual_text
	val_quality.modulate = qual_color
	val_ripeness.text = rip_text
	val_ripeness.modulate = rip_color
	val_quantity.text = quant_text
	val_quantity.modulate = quant_color
	
	val_plant.text = "$%d" % override_cost
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
	UIUtils.build_farm_timeline(timeline_container, 16, 16, 10, 2)

func _on_confirm() -> void:
	hide()
	
	var extra_data = {
		"harvest_method": selected_method,
		"override_cost": override_cost,
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
	hide()
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Harvest", current_tile, current_card_data)
	current_tile = null
	current_card_data = null
