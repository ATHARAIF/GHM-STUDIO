extends Node3D

@onready var popup_ui: CanvasLayer = $PopupUI
@onready var lbl_location: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/LblLocation
@onready var lbl_altitude: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAltitude
@onready var lbl_soil: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValSoil
@onready var lbl_aroma: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAroma
@onready var lbl_body: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValBody
@export var lbl_acidity: Label = null
@export var btn_close: Button = null
@export var timeline_container: HBoxContainer = null

var location: FarmLocation

func _ready() -> void:
	# Hubungkan references manual jika tidak ada
	popup_ui = $PopupUI
	lbl_location = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/LblLocation
	lbl_altitude = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAltitude
	lbl_soil = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValSoil
	lbl_aroma = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAroma
	lbl_body = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValBody
	lbl_acidity = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAcidity
	btn_close = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/BtnClose
	timeline_container = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Timeline
	
	location = StageManager.current_location
	
	if location:
		lbl_location.text = location.location_name
		lbl_altitude.text = "%dm" % location.altitude
		lbl_soil.text = "%d/100" % location.soil_quality
		
		if location.variety_data:
			lbl_aroma.text = "+%d" % location.variety_data.base_aroma
			lbl_body.text = "+%d" % location.variety_data.base_body
			lbl_acidity.text = "%d" % location.variety_data.base_acidity
		
	btn_close.pressed.connect(func(): popup_ui.hide())
	popup_ui.hide()
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(func(_a, _b, _c): popup_ui.hide())
		
	UIUtils.setup_input_blocker(popup_ui)

func _update_timeline() -> void:
	UIUtils.build_farm_timeline(timeline_container, 24, 30, 12, 4)

func _on_static_body_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_timeline()
		popup_ui.show()
