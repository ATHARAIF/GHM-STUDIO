extends Node3D

@export var interior_scene_path: String = "res://scenes/maps/warehouse.tscn"

func _ready() -> void:
	if has_node("ClickableArea"):
		$ClickableArea.input_event.connect(_on_clickable_area_input_event)
	else:
		print("WARNING: bldg_warehouse belum punya Area3D 'ClickableArea'!")

func _on_clickable_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Warehouse diklik! Menuju gudang...")
		
		# 1. Simpan ingatan ladang sebelum hancur
		if StageManager.has_method("save_room_state"):
			StageManager.save_room_state("farm")
			
		if not interior_scene_path.is_empty() and ResourceLoader.exists(interior_scene_path):
			await TransitionManager.fade_out()
			get_tree().change_scene_to_file(interior_scene_path)
			TransitionManager.fade_in()
		else:
			print("Interior scene belum ada/alamat salah: ", interior_scene_path)
