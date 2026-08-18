extends Area3D
 
@export var target_scene: String = "res://scenes/warehouse.tscn"
 
func _ready() -> void:
	input_event.connect(_on_input_event)
 
func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	print("Input event kena: ", event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Klik kiri terdeteksi, pindah ke: ", target_scene)
		get_tree().change_scene_to_file(target_scene)
