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
	
	_apply_factory_level()
	
	# 3. Load mesin-mesin yang sudah ditaruh di pabrik
	_spawn_factory_machines()
		
	# 4. Hubungkan tombol keluar
	if has_node("CanvasLayer/BtnExit"):
		get_node("CanvasLayer/BtnExit").pressed.connect(_on_btn_exit_pressed)

func _spawn_factory_machines() -> void:
	for m_id in FactoryManager.placed_machines:
		var m_data = FactoryManager.placed_machines[m_id]
		var item: ItemData = m_data["data"]
		
		# Pastikan item punya wujud 3D
		if item.tile_scene:
			var tile = item.tile_scene.instantiate()
			add_child(tile)
			
			# Gunakan sistem koordinat grid PlacementManager
			var coord = PlacementManager._world_to_grid(m_data["position"])
			if PlacementManager.grid.has(coord):
				var anchor = PlacementManager.grid[coord]
				var final_pos = anchor.global_position
				final_pos.y += PlacementManager.ground_top_offset - PlacementManager._get_bottom_y(tile)
				tile.global_position = final_pos
			else:
				tile.global_position = m_data["position"]
			
			# Daftar ke grid supaya bisa digeser-geser oleh PlacementManager
			PlacementManager.reoccupy_grid_for_restored_tile(tile, item)
			
			# Simpan referensi 3D node-nya agar UI bisa memberi highlight
			m_data["node"] = tile

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

var wall_container: Node3D = null

func _apply_factory_level() -> void:
	var lvl = FactoryManager.factory_level
	var bounds = {
		1: Rect2i(2, 2, 3, 4),
		2: Rect2i(1, 2, 5, 4),
		3: Rect2i(1, 1, 5, 5),
		4: Rect2i(0, 0, 7, 7)
	}
	var current_bound = bounds.get(lvl, bounds[1])
	
	var lvl_label_path = "prod_house_hud/prod_house_hud/building_hud/upgrade/MarginContainer/HBoxContainer/value"
	if has_node(lvl_label_path):
		get_node(lvl_label_path).text = str(lvl)
	
	# 1. Hide & Lock tiles outside bounds
	var coords_to_erase = []
	for coord in PlacementManager.grid:
		var tile = PlacementManager.grid[coord]
		var in_bounds = current_bound.has_point(coord)
		
		tile.is_locked = not in_bounds
		tile.visible = in_bounds
		if not in_bounds:
			coords_to_erase.append(coord)
			PlacementManager.ground_tiles.erase(tile)
			
	for coord in coords_to_erase:
		PlacementManager.grid.erase(coord)
		
	# 2. Build Walls
	if is_instance_valid(wall_container):
		wall_container.queue_free()
	
	wall_container = Node3D.new()
	wall_container.name = "Walls"
	add_child(wall_container)
	
	var cell_size = PlacementManager.cell_size
	var wall_thick = 0.15
	
	# Kalkulasi center dan ukuran bounds
	var center_grid_x = current_bound.position.x + (current_bound.size.x - 1) / 2.0
	var center_grid_z = current_bound.position.y + (current_bound.size.y - 1) / 2.0
	
	var center_x = PlacementManager.grid_origin.x + (center_grid_x * cell_size)
	var center_z = PlacementManager.grid_origin.z + (center_grid_z * cell_size)
	
	var width_x = current_bound.size.x * cell_size
	var depth_z = current_bound.size.y * cell_size
	
	var offset_x = (width_x / 2.0) + (wall_thick / 2.0)
	var offset_z = (depth_z / 2.0) + (wall_thick / 2.0)
	
	var base_pos = Vector3(center_x, 0, center_z)
	
	# Belakang Kiri (Top-Left Edge) -> +X direction
	_spawn_wall_segment(base_pos, Vector3(offset_x, 0, 0), Vector3(wall_thick, 1.0, depth_z + wall_thick*2), true, false)
	
	# Belakang Kanan (Top-Right Edge) -> +Z direction
	_spawn_wall_segment(base_pos, Vector3(0, 0, offset_z), Vector3(width_x + wall_thick*2, 0.3, wall_thick), false, true)
	
	# Depan Kiri (Bottom-Left Edge) -> -Z direction
	_spawn_wall_segment(base_pos, Vector3(0, 0, -offset_z), Vector3(width_x + wall_thick*2, 1.0, wall_thick), true, true)
	
	# Depan Kanan (Bottom-Right Edge) -> -X direction
	_spawn_wall_segment(base_pos, Vector3(-offset_x, 0, 0), Vector3(wall_thick, 0.3, depth_z + wall_thick*2), false, false)

@export var wall_high_scene: PackedScene
@export var wall_low_scene: PackedScene

func _spawn_wall_segment(base_pos: Vector3, offset: Vector3, size: Vector3, is_high: bool, is_z_axis: bool) -> void:
	var wall_node: Node3D
	
	# Kalau user sudah set scene di inspector, pakai scene itu!
	if is_high and wall_high_scene:
		wall_node = wall_high_scene.instantiate()
	elif not is_high and wall_low_scene:
		wall_node = wall_low_scene.instantiate()
	else:
		# Fallback kalau scene belum ada
		var csg = CSGBox3D.new()
		csg.size = size
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color("ca152d")
		csg.material = mat
		wall_node = csg
	
	wall_container.add_child(wall_node)
	
	var final_pos = base_pos + offset
	# Kalau pakai scene asli, anggap originnya ada di bawah. 
	# Kalau CSGBox originnya di tengah, jadi perlu ditambah size.y/2
	if wall_node is CSGBox3D:
		final_pos.y += PlacementManager.ground_top_offset + (size.y / 2.0)
	else:
		final_pos.y += PlacementManager.ground_top_offset
		# Putar mesh kalau dia dipasang sejajar sumbu Z
		if is_z_axis:
			wall_node.rotation_degrees.y = 90
		
	wall_node.global_position = final_pos
