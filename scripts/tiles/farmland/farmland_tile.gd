extends Node3D

@onready var popup_ui: CanvasLayer = $FarmlandDetailPopup
var location: FarmLocation

func _ready() -> void:
	location = StageManager.current_location
	
	if popup_ui:
		popup_ui.hide()

func _on_static_body_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if popup_ui and popup_ui.has_method("setup_data"):
			popup_ui.setup_data(location)
			popup_ui.show()
