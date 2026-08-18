extends Node

## Autoload. Project Settings > Autoload, Node Name: "WarehousePlacement".
##
## Cara pakai (di script scene 3D tiap bangunan, di _ready(), URUTAN PENTING):
##     WarehousePlacement.set_building_id("warehouse")   # ganti sesuai bangunan
##     WarehousePlacement.register_camera($Camera3D)
##     WarehousePlacement.register_floor($tile_grounds)
##     WarehousePlacement.register_items_container($PlacedItems)
##     WarehousePlacement.rebuild_placed_items()          # WAJIB PALING TERAKHIR
##
## - Di item_card.gd, pas beli berhasil:  WarehousePlacement.spawn_item(item_data)
## - Di item_card.gd, pas sell berhasil:  WarehousePlacement.remove_one(item_data)
##
## Item bisa punya footprint > 1x1 (ItemData.footprint_size). Sistem ini
## nge-occupy BEBERAPA kotak grid sekaligus buat item gede, dan footprint-nya
## otomatis kebalik (lebar <-> dalam) kalau item-nya diputer 90/270 derajat.
##
## Kontrol pas main:
## - Klik kiri item -> select (jadi kuning)
## - Tahan klik kiri + geser -> item keangkat + indikator kotak tujuan
##   (ijo = valid, merah = nggak bisa), ukuran indikator ngikutin footprint item
## - Lepas mouse di area valid -> commit, snap ke grid
## - Lepas mouse di area invalid -> balik ke posisi semula
## - Tombol R -> rotate 90 derajat (dibatalin otomatis kalau abis diputer
##   jadi nabrak item lain)
## - Klik di lantai kosong -> deselect

const PLACED_ITEM_SCENE: PackedScene = preload("res://scenes/items/placed_item.tscn")  # sesuaikan path
const DRAG_LIFT_HEIGHT: float = 0.3

signal spawn_failed_full
signal field_full_changed(is_full: bool)
signal placement_changed

@export var tile_size: float = 1.0
@export var max_search_radius: int = 20
@export var rotate_search_radius: int = 2  # radius kecil buat "rotate pintar" -- item cuma geser dikit, nggak lompat jauh

var camera: Camera3D
var items_container: Node3D
var current_building_id: String = ""
var selected_item: PlacedItem = null
var is_dragging: bool = false
var drag_start_position: Vector3 = Vector3.ZERO
var _drag_hover_anchor: Vector2i = Vector2i.ZERO
var _drag_rotation_steps: int = 0  # rotasi SEMENTARA pas lagi drag aktif, dipake buat preview
var floor_y: float = 0.0
var valid_floor_cells: Dictionary = {}       # { Vector2i: true }
var occupied_cells: Dictionary = {}          # { Vector2i: PlacedItem }
var placed_items_by_type: Dictionary = {}    # { ItemData: Array[PlacedItem] }
var item_to_record: Dictionary = {}          # { PlacedItem: Dictionary record }
var placement_records: Array = []            # [{item_data, cell, rotation_steps, building_id}]
var _indicator: MeshInstance3D = null

## WAJIB dipanggil PALING AWAL di _ready() tiap scene bangunan.
func set_building_id(id: String) -> void:
	current_building_id = id

func register_camera(cam: Camera3D) -> void:
	camera = cam

func register_items_container(container: Node3D) -> void:
	items_container = container
	occupied_cells.clear()
	placed_items_by_type.clear()
	item_to_record.clear()
	_setup_indicator()

func register_floor(floor_node: Node3D) -> void:
	var meshes := _find_mesh_instances(floor_node)
	if meshes.is_empty():
		push_warning("WarehousePlacement: register_floor nggak nemu MeshInstance3D apapun di bawah node ini")
		return

	valid_floor_cells.clear()
	var top_y: float = -INF

	for mesh in meshes:
		var global_aabb: AABB = mesh.global_transform * mesh.get_aabb()
		var center := global_aabb.position + global_aabb.size * 0.5
		var cell := _to_grid(center)
		valid_floor_cells[cell] = true
		top_y = maxf(top_y, global_aabb.position.y + global_aabb.size.y)

	floor_y = top_y

func rebuild_placed_items() -> void:
	if items_container == null:
		push_warning("WarehousePlacement: rebuild_placed_items dipanggil sebelum items_container di-register")
		return
	for record in placement_records:
		if record.get("building_id", "") == current_building_id:
			_instantiate_record(record)
	placement_changed.emit()

func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result

## --- Grid & footprint helpers ---

func _to_grid(pos: Vector3) -> Vector2i:
	return Vector2i(int(round(pos.x / tile_size)), int(round(pos.z / tile_size)))

func _from_grid(cell: Vector2i) -> Vector3:
	return Vector3(float(cell.x) * tile_size, floor_y, float(cell.y) * tile_size)

## Ukuran efektif (kena rotate atau nggak): rotasi ganjil (90/270) -> kebalik.
func _effective_footprint(item_data: ItemData, rotation_steps: int) -> Vector2i:
	var size := item_data.footprint_size
	if rotation_steps % 2 == 1:
		return Vector2i(size.y, size.x)
	return size

## Semua kotak grid yang kepake, dari anchor (pojok) sepanjang size.
func _footprint_cells(anchor: Vector2i, size: Vector2i) -> Array:
	var cells: Array = []
	for dx in range(size.x):
		for dz in range(size.y):
			cells.append(anchor + Vector2i(dx, dz))
	return cells

## Posisi dunia titik TENGAH footprint (buat naro visual item, biar center
## pas di tengah areanya, bukan mepet ke satu pojok).
func _footprint_world_position(anchor: Vector2i, size: Vector2i) -> Vector3:
	var base := _from_grid(anchor)
	var offset_x := float(size.x - 1) * tile_size * 0.5
	var offset_z := float(size.y - 1) * tile_size * 0.5
	return base + Vector3(offset_x, 0.0, offset_z)

func _is_cell_on_floor(cell: Vector2i) -> bool:
	return valid_floor_cells.has(cell)

func _is_footprint_free(cells: Array, ignore_item: PlacedItem = null) -> bool:
	for cell in cells:
		if not _is_cell_on_floor(cell):
			return false
		var occupant = occupied_cells.get(cell)
		if occupant != null and occupant != ignore_item:
			return false
	return true

## Cari anchor kosong terdekat dari titik acuan buat footprint tertentu,
## spiral keluar. Return null kalau nggak ketemu sama sekali.
func _find_empty_anchor(origin_pos: Vector3, footprint_size: Vector2i):
	var origin_cell := _to_grid(origin_pos)
	if _is_footprint_free(_footprint_cells(origin_cell, footprint_size)):
		return origin_cell

	for radius in range(1, max_search_radius + 1):
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dz)) != radius:
					continue
				var cell := origin_cell + Vector2i(dx, dz)
				if _is_footprint_free(_footprint_cells(cell, footprint_size)):
					return cell

	return null

func has_empty_cell() -> bool:
	if items_container == null or not items_container.is_inside_tree():
		return false
	return _find_empty_anchor(items_container.global_position, Vector2i(1, 1)) != null

func get_owned_items_in_building() -> Array:
	return placed_items_by_type.keys()

func get_owned_count_in_building(item_data: ItemData) -> int:
	if not placed_items_by_type.has(item_data):
		return 0
	return placed_items_by_type[item_data].size()

## --- Spawn, rebuild, remove ---

func _instantiate_record(record: Dictionary) -> PlacedItem:
	var item := PLACED_ITEM_SCENE.instantiate() as PlacedItem
	items_container.add_child(item)

	var item_data: ItemData = record["item_data"]
	var rotation_steps: int = record.get("rotation_steps", 0)
	var effective_size := _effective_footprint(item_data, rotation_steps)
	var cells := _footprint_cells(record["cell"], effective_size)

	item.global_position = _footprint_world_position(record["cell"], effective_size)
	item.rotation.y = float(rotation_steps) * (PI * 0.5)
	item.setup(item_data, tile_size)

	item.set_meta("footprint_cells", cells)

	for cell in cells:
		occupied_cells[cell] = item

	if not placed_items_by_type.has(item_data):
		placed_items_by_type[item_data] = []
	placed_items_by_type[item_data].append(item)

	item_to_record[item] = record
	return item

func spawn_item(item_data: ItemData) -> PlacedItem:
	if items_container == null or not items_container.is_inside_tree():
		push_warning("WarehousePlacement: items_container belum di-register")
		return null

	var anchor = _find_empty_anchor(items_container.global_position, item_data.footprint_size)
	if anchor == null:
		push_warning("WarehousePlacement: lantai penuh, nggak ada kotak kosong buat item baru")
		spawn_failed_full.emit()
		return null

	var record := {
		"item_data": item_data,
		"cell": anchor,
		"rotation_steps": 0,
		"building_id": current_building_id,
	}
	placement_records.append(record)
	var item := _instantiate_record(record)

	field_full_changed.emit(not has_empty_cell())
	placement_changed.emit()
	return item

func remove_one(item_data: ItemData) -> bool:
	if not placed_items_by_type.has(item_data):
		return false
	var list: Array = placed_items_by_type[item_data]
	if list.is_empty():
		return false

	var item: PlacedItem = list.pop_back()
	if list.is_empty():
		placed_items_by_type.erase(item_data)

	if item.has_meta("footprint_cells"):
		var cells: Array = item.get_meta("footprint_cells")
		for cell in cells:
			if occupied_cells.get(cell) == item:
				occupied_cells.erase(cell)

	if item_to_record.has(item):
		placement_records.erase(item_to_record[item])
		item_to_record.erase(item)

	if item == selected_item:
		_deselect()
	item.queue_free()
	field_full_changed.emit(not has_empty_cell())
	placement_changed.emit()
	return true

## --- Indikator drag ---

func _setup_indicator() -> void:
	if items_container == null:
		return
	_indicator = MeshInstance3D.new()
	var quad := BoxMesh.new()
	quad.size = Vector3(tile_size * 0.95, 0.02, tile_size * 0.95)
	_indicator.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
	_indicator.material_override = mat
	_indicator.visible = false
	items_container.add_child(_indicator)

func _show_indicator(center_pos: Vector3, size: Vector2i, is_valid: bool) -> void:
	if _indicator == null:
		return
	_indicator.visible = true
	var quad := _indicator.mesh as BoxMesh
	quad.size = Vector3(float(size.x) * tile_size * 0.95, 0.02, float(size.y) * tile_size * 0.95)
	_indicator.global_position = center_pos + Vector3(0.0, 0.02, 0.0)
	var mat := _indicator.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.3, 1.0, 0.3, 0.5) if is_valid else Color(1.0, 0.3, 0.3, 0.5)

func _hide_indicator() -> void:
	if _indicator:
		_indicator.visible = false

## --- Input, drag, rotate ---

func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_select(event.position)
		else:
			_finish_drag()

	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if selected_item:
			if is_dragging:
				_rotate_during_drag(selected_item)
			else:
				_try_rotate(selected_item)

	elif event is InputEventMouseMotion and is_dragging and selected_item:
		_drag_to(event.position)

func _try_select(mouse_pos: Vector2) -> void:
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0
	var space_state := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)

	if result and result.collider is PlacedItem:
		_select(result.collider)
		is_dragging = true
		drag_start_position = result.collider.global_position
		_drag_hover_anchor = _to_grid(drag_start_position)  # biar ada nilai awal yang valid, bukan basi
		if item_to_record.has(result.collider):
			_drag_rotation_steps = item_to_record[result.collider].get("rotation_steps", 0)
		else:
			_drag_rotation_steps = 0
	else:
		_deselect()

func _select(item: PlacedItem) -> void:
	if selected_item and selected_item != item:
		selected_item.set_selected(false)
	selected_item = item
	selected_item.set_selected(true)

func _deselect() -> void:
	if selected_item:
		selected_item.set_selected(false)
	selected_item = null
	is_dragging = false
	_hide_indicator()

func _drag_to(mouse_pos: Vector2) -> void:
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	if absf(dir.y) < 0.0001:
		return
	var t := (floor_y - from.y) / dir.y
	if t < 0:
		return
	var hit := from + dir * t
	var hover_anchor := _to_grid(hit)
	_drag_hover_anchor = hover_anchor

	var effective_size := Vector2i(1, 1)
	if item_to_record.has(selected_item):
		var record: Dictionary = item_to_record[selected_item]
		effective_size = _effective_footprint(record["item_data"], _drag_rotation_steps)

	var preview_pos := _footprint_world_position(hover_anchor, effective_size)
	selected_item.global_position = Vector3(preview_pos.x, floor_y + DRAG_LIFT_HEIGHT, preview_pos.z)

	var cells := _footprint_cells(hover_anchor, effective_size)
	var is_valid := _is_footprint_free(cells, selected_item)
	_show_indicator(preview_pos, effective_size, is_valid)

func _finish_drag() -> void:
	if is_dragging and selected_item and item_to_record.has(selected_item):
		var record: Dictionary = item_to_record[selected_item]
		var item_data: ItemData = record["item_data"]
		var effective_size := _effective_footprint(item_data, _drag_rotation_steps)
		var candidate_anchor: Vector2i = _drag_hover_anchor
		var new_cells := _footprint_cells(candidate_anchor, effective_size)

		if _is_footprint_free(new_cells, selected_item):
			var old_cells: Array = selected_item.get_meta("footprint_cells", [])
			for cell in old_cells:
				if occupied_cells.get(cell) == selected_item:
					occupied_cells.erase(cell)
			for cell in new_cells:
				occupied_cells[cell] = selected_item
			selected_item.set_meta("footprint_cells", new_cells)
			selected_item.rotation.y = float(_drag_rotation_steps) * (PI * 0.5)
			selected_item.global_position = _footprint_world_position(candidate_anchor, effective_size)
			record["cell"] = candidate_anchor
			record["rotation_steps"] = _drag_rotation_steps
		else:
			selected_item.rotation.y = float(record.get("rotation_steps", 0)) * (PI * 0.5)
			selected_item.global_position = drag_start_position
	is_dragging = false
	_hide_indicator()
	field_full_changed.emit(not has_empty_cell())

## Rotate PAS LAGI DRAG AKTIF (mouse masih ditahan). Ini CUMA preview --
## nggak nyentuh occupied_cells/record sama sekali. Posisi & validitas
## final tetep ditentuin di _finish_drag() pas mouse dilepas, pake
## _drag_rotation_steps yang di-update di sini.
func _rotate_during_drag(item: PlacedItem) -> void:
	_drag_rotation_steps = (_drag_rotation_steps + 1) % 4
	item.rotation.y = float(_drag_rotation_steps) * (PI * 0.5)

	if not item_to_record.has(item):
		return
	var record: Dictionary = item_to_record[item]
	var effective_size := _effective_footprint(record["item_data"], _drag_rotation_steps)

	var preview_pos := _footprint_world_position(_drag_hover_anchor, effective_size)
	item.global_position = Vector3(preview_pos.x, floor_y + DRAG_LIFT_HEIGHT, preview_pos.z)

	var cells := _footprint_cells(_drag_hover_anchor, effective_size)
	var is_valid := _is_footprint_free(cells, item)
	_show_indicator(preview_pos, effective_size, is_valid)

func _try_rotate(item: PlacedItem) -> void:
	if not item_to_record.has(item):
		return
	var record: Dictionary = item_to_record[item]
	var item_data: ItemData = record["item_data"]
	var old_rotation: int = record.get("rotation_steps", 0)
	var new_rotation: int = (old_rotation + 1) % 4
	var old_anchor: Vector2i = record["cell"]
	var new_size := _effective_footprint(item_data, new_rotation)

	var new_anchor = _find_nearby_anchor(old_anchor, new_size, item)
	if new_anchor == null:
		return  # beneran nggak ada ruang di sekitar sini, batal rotate

	var new_cells := _footprint_cells(new_anchor, new_size)

	var old_cells: Array = item.get_meta("footprint_cells", [])
	for cell in old_cells:
		if occupied_cells.get(cell) == item:
			occupied_cells.erase(cell)
	for cell in new_cells:
		occupied_cells[cell] = item

	item.set_meta("footprint_cells", new_cells)
	record["rotation_steps"] = new_rotation
	record["cell"] = new_anchor
	_drag_hover_anchor = new_anchor  # sinkronin, biar kalau langsung dilepas tanpa digeser, tetep bener
	item.rotation.y = float(new_rotation) * (PI * 0.5)
	item.global_position = _footprint_world_position(new_anchor, new_size)

## "Rotate pintar": kalau anchor asli kepentok abis rotate, nyoba geser
## anchor ke kotak-kotak terdekat di sekitarnya (spiral keluar, dalam
## radius kecil) sebelum bener-bener nyerah. Item jadi kerasa "geser
## dikit" pas muter, bukan diem doang kalau ruangnya sempit.
func _find_nearby_anchor(origin_cell: Vector2i, size: Vector2i, ignore_item: PlacedItem):
	if _is_footprint_free(_footprint_cells(origin_cell, size), ignore_item):
		return origin_cell

	for radius in range(1, rotate_search_radius + 1):
		for dx in range(-radius, radius + 1):
			for dz in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dz)) != radius:
					continue
				var cell := origin_cell + Vector2i(dx, dz)
				if _is_footprint_free(_footprint_cells(cell, size), ignore_item):
					return cell

	return null
