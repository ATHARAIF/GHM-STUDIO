extends Node3D

@export var farm_scene_path: String = "res://scenes/maps/main_farm.tscn"

func _ready() -> void:
	# 1. Daftarkan Kamera Pabrik (Kalau ada)
	if has_node("Camera3D"):
		PlacementManager.register_camera($Camera3D)
		
	# 2. Daftarkan lantai grid pabrik (Kalau ada)
	var tiles: Array[GroundTile] = []
	_collect_ground_tiles(self, tiles)
	PlacementManager.register_ground_tiles(tiles)
	
	# 3. Load mesin-mesin yang sudah ditaruh di pabrik
	if StageManager.has_method("restore_room_state"):
		StageManager.restore_room_state("prod_house")
		
	# 4. Hubungkan tombol keluar
	if has_node("CanvasLayer/BtnExit"):
		get_node("CanvasLayer/BtnExit").pressed.connect(_on_btn_exit_pressed)

func _on_btn_exit_pressed() -> void:
	print("Keluar dari pabrik, kembali ke ladang...")
	
	# 1. Simpan posisi mesin-mesin di pabrik
	if StageManager.has_method("save_room_state"):
		StageManager.save_room_state("prod_house")
		
	# 2. Pindah scene
	if not farm_scene_path.is_empty() and ResourceLoader.exists(farm_scene_path):
		await TransitionManager.fade_out()
		get_tree().change_scene_to_file(farm_scene_path)
		TransitionManager.fade_in()

func _collect_ground_tiles(node: Node, tiles: Array[GroundTile]) -> void:
	for child in node.get_children():
		if child is GroundTile:
			tiles.append(child)
		_collect_ground_tiles(child, tiles)
