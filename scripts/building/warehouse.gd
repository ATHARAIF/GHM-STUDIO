extends Node3D

@export var warehouse_field_node: Node3D

var original_camera_pos: Vector3
var original_camera_rot: Vector3
var _original_parent: Node
var _parent_building: Node3D

func _ready():
	WarehousePlacement.set_building_id("warehouse")
	WarehousePlacement.register_camera($Camera3D)
	WarehousePlacement.register_items_container($PlacedItems)
	WarehousePlacement.register_floor($tile_grounds)
	WarehousePlacement.rebuild_placed_items()
	var cam = get_viewport().get_camera_3d()
	if cam:
		original_camera_pos = cam.global_position
		original_camera_rot = cam.rotation

func _on_click_area_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Area di klik")
		open_warehouse_field()

func open_warehouse_field():
	print("=== MEMBUKA WAREHOUSE FIELD ===")
	
	if warehouse_field_node == null:
		return
	
	# 1. Sembunyikan HANYA bangunan putih
	_parent_building = warehouse_field_node.get_parent()
	if _parent_building:
		_parent_building.visible = false
	
	# 2. Pindahkan WarehouseField ke root
	var original_pos = warehouse_field_node.global_position
	_original_parent = _parent_building
	
	if _original_parent:
		_original_parent.remove_child(warehouse_field_node)
	
	get_tree().root.add_child(warehouse_field_node)
	
	# PENTING: Turunkan parent ke Y=0.1 (hampir di tanah)
	warehouse_field_node.global_position = Vector3(original_pos.x, 0.1, original_pos.z)
	warehouse_field_node.visible = true
	
	# PENTING: Naikkan semua anak (GridVisual, Floor_Visual, dll) agar tidak masuk tanah
	# Karena parent turun 0.59 (dari 0.69 ke 0.1), kita naikkan anak-anaknya 0.59
	for child in warehouse_field_node.get_children():
		if child is Node3D:
			child.position.y += 0.59
	
	if warehouse_field_node.has_method("enable_placement"):
		warehouse_field_node.enable_placement()
	
	# 3. Hapus kamera internal
	var cam_internal = warehouse_field_node.get_node_or_null("Camera3D")
	if cam_internal:
		cam_internal.queue_free()
	
	# 4. BUAT SLAB TIPIS DI TANAH (Y=0)
	_create_warehouse_room(warehouse_field_node.global_position)
	
	# 5. SETUP KAMERA
	var main_cam = get_node_or_null("/root/ground/Camera3D")
	if main_cam:
		main_cam.current = true
		main_cam.cull_mask = 1048575
		
		var field_pos = warehouse_field_node.global_position
		main_cam.global_position = field_pos + Vector3(4, 5, 4)
		main_cam.look_at(field_pos + Vector3(0, 1, 0))
		
		print("Kamera zoom in ke warehouse")
	
	# 6. Sembunyikan UI utama
	var main_ui = get_node_or_null("/root/ground/MainHUD")
	if main_ui:
		main_ui.visible = false
	
	print("=== WAREHOUSE FIELD TERBUKA ===")
	
func _create_warehouse_room(center_pos: Vector3):
	var old_room = get_node_or_null("/root/WarehouseRoom")
	if old_room:
		old_room.queue_free()
	
	var room_container = Node3D.new()
	room_container.name = "WarehouseRoom"
	get_tree().root.add_child(room_container)
	
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.9, 0.88, 0.8) # Krem keputihan
	
	# SLAB TIPIS DI TANAH (Y=0)
	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(4.5, 0.1, 4.5) # Tebal 0.1
	base.mesh = base_mesh
	base.material_override = base_mat
	room_container.add_child(base)
	base.global_position = Vector3(center_pos.x, 0.0, center_pos.z) # Tepat di tanah
	
	print("Slab tipis dibuat di tanah!")

func close_warehouse_field():
	print("=== MENUTUP WAREHOUSE FIELD ===")
	
	if _parent_building:
		_parent_building.visible = true
	
	if warehouse_field_node and _original_parent:
		var pos = warehouse_field_node.global_position
		get_tree().root.remove_child(warehouse_field_node)
		_original_parent.add_child(warehouse_field_node)
		
		# Kembalikan anak-anak ke posisi asal (kurangi 0.59)
		for child in warehouse_field_node.get_children():
			if child is Node3D:
				child.position.y -= 0.59
		
		# Kembalikan parent ke posisi asli
		warehouse_field_node.global_position = Vector3(pos.x, 0.691283, pos.z)
		warehouse_field_node.visible = false
		
		if warehouse_field_node.has_method("disable_placement"):
			warehouse_field_node.disable_placement()
	
	var main_cam = get_node_or_null("/root/ground/Camera3D")
	if main_cam:
		main_cam.global_position = original_camera_pos
		main_cam.rotation = original_camera_rot
	
	var main_ui = get_node_or_null("/root/ground/MainHUD")
	if main_ui:
		main_ui.visible = true
	
	print("=== WAREHOUSE FIELD DITUTUP ===")
