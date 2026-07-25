extends Node

@export_group("Ghost Visual")
@export var float_height: float = 0.4
@export var ghost_float_alpha: float = 0.55
@export var ghost_indicator_alpha: float = 0.25
@export var valid_color: Color = Color(0.3, 1, 0.3)   # jika mau ngikut warna asli tile, biarin putih & pastikan use_original_color_when_valid = true
@export var invalid_color: Color = Color(1, 0.3, 0.3)
#@export var use_original_color_when_valid: bool = true

@export_group("Animation")
@export var rotate_duration: float = 0.2
@export var place_duration: float = 0.35

@export_group("UI")
@export var pruning_popup: CanvasLayer

var camera: Camera3D
var ghost_float: Node3D      # tile yang ngambang, ngikutin cursor
var ghost_indicator: Node3D  # "bayangan" rata di ground, nunjukin valid/invalid
var current_tile_scene: PackedScene
var current_base_shape: Array[Vector2i] = [Vector2i.ZERO]   # shape asli, belum dirotate
var current_shape: Array[Vector2i] = [Vector2i.ZERO]        # shape setelah dirotate, dipake buat validasi
var rotation_steps: int = 0   # 0-3, tiap step = 90 derajat
var ghost_visual_rotation: float = 0.0   # rotasi kontinu (gak di-wrap), buat animasi tween

var ground_tiles: Array[GroundTile] = []
var grid: Dictionary = {}          # Vector2i -> GroundTile
var cell_size: float = 2.0
var grid_origin: Vector3 = Vector3.ZERO

var ground_top_offset: float = 0.0
var tile_bottom_offset: float = 0.0

var placement_data: Dictionary = {}   # tile_instance (Node3D) -> {scene, base_shape, shape, anchor, rotation_steps, card_node}

var current_card_node: Control = null   # referensi LANGSUNG ke node Card asli yang lagi di-drag (bukan path/scene)
var pending_pruning_tile: Node3D = null

func _input(event: InputEvent) -> void:
	# pake _input (bukan _unhandled_input) biar gak ketelen sama Control/GUI manapun
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_tile_scene == null:
			_try_pickup(event.position)

func _try_pickup(mouse_pos: Vector2) -> void:
	var world_pos = _get_ground_position(mouse_pos)
	if world_pos == null:
		return

	var coord := _world_to_grid(world_pos)
	if not grid.has(coord):
		return

	var gt: GroundTile = grid[coord]
	if not gt.is_occupied:
		return

	var tile: Node3D = gt.placed_tile
	if not placement_data.has(tile):
		return   # data gak ketemu, aman-in aja gak diapa-apain
		
	if StageManager.is_tile_ready_for_interaction(tile):
		StageManager.trigger_interaction(tile)
		return
		
	if StageManager.is_tile_locked(tile):
		return   # sudah dikunci oleh StageManager (sudah end turn)

	var data: Dictionary = placement_data[tile]
	var card_node: Control = data.get("card_node", null)

	if card_node == null or not is_instance_valid(card_node):
		return   # card aslinya udah gak ada (edge case), jangan diapa-apain

	# lepas semua cell yang tadi ditempatin tile ini
	for offset in data.shape:
		var c: Vector2i = data.anchor + offset
		if grid.has(c):
			grid[c].clear()

	StageManager.unregister_placed_tile(tile)
	placement_data.erase(tile)
	tile.queue_free()

	# balikin ke state [2] pake NODE CARD ASLINYA -- bukan bikin card baru.
	# semua data (label, ukuran, dll) otomatis ikut karena ini instance yang sama persis.
	card_node.resume_drag_at(mouse_pos, data.rotation_steps)

func register_camera(cam: Camera3D) -> void:
	camera = cam

func register_ground_tiles(tiles: Array[GroundTile]) -> void:
	ground_tiles = tiles
	if tiles.is_empty():
		return

	ground_top_offset = _get_half_height(tiles[0])
	cell_size = _detect_cell_size(tiles)
	grid_origin = _find_min_corner(tiles)

	grid.clear()
	for gt in tiles:
		var coord := _world_to_grid(gt.global_position)
		gt.grid_coord = coord
		grid[coord] = gt

var shape_cache: Dictionary = {}   # PackedScene -> Array[Vector2i], biar gak itung ulang tiap drag

func begin_drag(tile_scene: PackedScene, card_node: Control = null, initial_rotation_steps: int = 0) -> void:
	current_tile_scene = tile_scene
	current_card_node = card_node
	current_base_shape = _get_shape(tile_scene)
	rotation_steps = initial_rotation_steps
	ghost_visual_rotation = float(initial_rotation_steps) * 90.0
	current_shape = _rotate_shape(current_base_shape, rotation_steps)
	var temp = tile_scene.instantiate()
	tile_bottom_offset = _get_half_height(temp)
	temp.free()

func rotate_ghost() -> void:
	if current_tile_scene == null:
		return

	rotation_steps = (rotation_steps + 1) % 4
	current_shape = _rotate_shape(current_base_shape, rotation_steps)

	ghost_visual_rotation += 90.0   # terus nambah (gak di-wrap), biar tween-nya muter searah terus

	if ghost_float:
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK)
		tw.set_ease(Tween.EASE_OUT)
		tw.tween_property(ghost_float, "rotation_degrees:y", ghost_visual_rotation, rotate_duration)

	if ghost_indicator:
		var tw2 := create_tween()
		tw2.set_trans(Tween.TRANS_BACK)
		tw2.set_ease(Tween.EASE_OUT)
		tw2.tween_property(ghost_indicator, "rotation_degrees:y", ghost_visual_rotation, rotate_duration)

func _rotate_shape(shape: Array[Vector2i], steps: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = shape.duplicate()
	for i in steps:
		var rotated: Array[Vector2i] = []
		for cell in result:
			rotated.append(Vector2i(cell.y, -cell.x))   # match arah rotation_degrees.y bawaan Godot
		result = rotated
	return result

func end_drag() -> void:
	_clear_ghost()
	current_tile_scene = null
	current_card_node = null

func cancel_ghost() -> void:
	_clear_ghost()

func update_ghost(mouse_pos: Vector2) -> void:
	if camera == null or current_tile_scene == null:
		return

	var world_pos = _get_ground_position(mouse_pos)
	if world_pos == null:
		return

	if ghost_float == null:
		ghost_float = current_tile_scene.instantiate()
		_apply_native_transparency(ghost_float, ghost_float_alpha)
		ghost_float.rotation_degrees.y = rotation_steps * 90.0
		get_tree().current_scene.add_child(ghost_float)

	if ghost_indicator == null:
		ghost_indicator = current_tile_scene.instantiate()
		_strip_to_base_tile(ghost_indicator)
		_make_flat_shadow(ghost_indicator, ghost_indicator_alpha)
		ghost_indicator.rotation_degrees.y = rotation_steps * 90.0
		get_tree().current_scene.add_child(ghost_indicator)
		ghost_visual_rotation = rotation_steps * 90.0

	var anchor_coord := _world_to_grid(world_pos)
	var valid := _can_place(anchor_coord, current_shape)

	var base_pos: Vector3
	if valid:
		var anchor_tile: GroundTile = grid[anchor_coord]
		base_pos = anchor_tile.global_position
		base_pos.y += ground_top_offset + tile_bottom_offset
	else:
		base_pos = world_pos   # gak snap, ngikut posisi mouse bebas

	ghost_indicator.global_position = base_pos

	var float_pos := base_pos
	float_pos.y += float_height
	ghost_float.global_position = float_pos

	_tint_shadow(ghost_indicator, not valid)

func try_place(mouse_pos: Vector2, tile_scene: PackedScene, card_data: CardData) -> bool:
	var world_pos = _get_ground_position(mouse_pos)
	_clear_ghost()

	if world_pos == null:
		return false

	var shape := current_shape   # shape yang lagi aktif (udah kena rotate kalau ada)
	var anchor_coord := _world_to_grid(world_pos)
	if not _can_place(anchor_coord, shape):
		return false

	var anchor_tile: GroundTile = grid[anchor_coord]
	var tile := tile_scene.instantiate()
	get_tree().current_scene.add_child(tile)

	var final_pos = anchor_tile.global_position
	final_pos.y += ground_top_offset + tile_bottom_offset
	tile.rotation_degrees.y = rotation_steps * 90.0

	# spawn di posisi ghost float (ngambang), baru animasi jatuh ke posisi final
	var start_pos = final_pos
	start_pos.y += float_height
	tile.global_position = start_pos

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BOUNCE)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(tile, "global_position", final_pos, place_duration)

	for offset in shape:
		var coord = anchor_coord + offset
		var gt: GroundTile = grid[coord]
		gt.occupy(tile)

	placement_data[tile] = {
		"scene": tile_scene,
		"base_shape": current_base_shape.duplicate(),
		"shape": shape.duplicate(),
		"anchor": anchor_coord,
		"rotation_steps": rotation_steps,
		"card_node": current_card_node,
		"card_data": card_data
	}
	
	if card_data != null:
		if card_data.card_name == "Pruning":
			pending_pruning_tile = tile
			if pruning_popup:
				pruning_popup.show_popup()
		else:
			StageManager.register_placed_tile(tile, card_data)

	current_tile_scene = null   # reset, biar pickup detection ("current_tile_scene == null") gak ke-block
	current_card_node = null

	return true

func _on_pruning_confirmed(method: String, intensity: float) -> void:
	if pending_pruning_tile and placement_data.has(pending_pruning_tile):
		var data = placement_data[pending_pruning_tile]
		data["pruning_method"] = method
		data["pruning_intensity"] = intensity
		StageManager.register_placed_tile(pending_pruning_tile, data["card_data"], {
			"pruning_method": method,
			"pruning_intensity": intensity
		})
	pending_pruning_tile = null

func _on_pruning_cancelled() -> void:
	if pending_pruning_tile and placement_data.has(pending_pruning_tile):
		var data = placement_data[pending_pruning_tile]
		var card = data.get("card_node", null)
		
		# Free occupied cells
		for offset in data.shape:
			var c: Vector2i = data.anchor + offset
			if grid.has(c):
				grid[c].clear()
				
		placement_data.erase(pending_pruning_tile)
		pending_pruning_tile.queue_free()
		
		# Return card to hand using the card's native animation logic
		if card and is_instance_valid(card):
			if card.has_method("set"):
				card.set("is_placed", false)
				card.show()
				card.set("top_level", true)
				var op = card.get("origin_parent")
				var oi = card.get("origin_index")
				if op:
					op.move_child(card, oi)
				card.call("animate_return_from", card.global_position)
				
	pending_pruning_tile = null

func _can_place(anchor_coord: Vector2i, shape: Array[Vector2i]) -> bool:
	for offset in shape:
		var coord = anchor_coord + offset
		if not grid.has(coord):
			return false          # cell di luar area ground
		var gt: GroundTile = grid[coord]
		if gt.is_occupied:
			return false          # cell udah ketiban tile lain
	return true

func _get_shape(tile_scene: PackedScene) -> Array[Vector2i]:
	if shape_cache.has(tile_scene):
		return shape_cache[tile_scene]

	var shape := _compute_shape_from_scene(tile_scene)
	shape_cache[tile_scene] = shape
	return shape

func _compute_shape_from_scene(tile_scene: PackedScene) -> Array[Vector2i]:
	var temp: Node3D = tile_scene.instantiate()

	var shape: Array[Vector2i] = []

	var base := _find_base_tile_node(temp)
	if base:
		# base_tile posisinya sendiri bisa aja offset dari root tile_scene,
		# jadi mulai hitung dari posisi lokal base_tile itu, bukan dari 0.
		_collect_mesh_cells(base, base.position, shape)
	else:
		# fallback jaga-jaga: kalau gak ada node "base_tile", pake cara lama (semua mesh)
		_collect_mesh_cells(temp, Vector3.ZERO, shape)

	if shape.is_empty():
		shape.append(Vector2i.ZERO)

	temp.free()
	return shape

func _find_base_tile_node(node: Node) -> Node3D:
	for child in node.get_children():
		if child.name == "base tile" and child is Node3D:
			return child
		var found := _find_base_tile_node(child)
		if found:
			return found
	return null

func _collect_mesh_cells(node: Node3D, parent_offset: Vector3, shape: Array[Vector2i]) -> void:
	for child in node.get_children():
		if child is Node3D:
			if child.name.to_lower() == "decoration":
				continue   # skip total, gak peduli nested di mana pun posisinya

			var rel: Vector3 = parent_offset + child.position
			if child is MeshInstance3D:
				var cell := Vector2i(int(round(rel.x / cell_size)), int(round(rel.z / cell_size)))
				if not shape.has(cell):
					shape.append(cell)
			_collect_mesh_cells(child, rel, shape)

func _world_to_grid(pos: Vector3) -> Vector2i:
	var col := int(round((pos.x - grid_origin.x) / cell_size))
	var row := int(round((pos.z - grid_origin.z) / cell_size))
	return Vector2i(col, row)

func _detect_cell_size(tiles: Array[GroundTile]) -> float:
	var min_dist := INF
	for i in tiles.size():
		for j in tiles.size():
			if i == j:
				continue
			var d = Vector2(tiles[i].global_position.x, tiles[i].global_position.z) \
				.distance_to(Vector2(tiles[j].global_position.x, tiles[j].global_position.z))
			if d > 0.01 and d < min_dist:
				min_dist = d
	return min_dist if min_dist != INF else 2.0

func _find_min_corner(tiles: Array[GroundTile]) -> Vector3:
	var min_pos: Vector3 = tiles[0].global_position
	for gt in tiles:
		min_pos.x = min(min_pos.x, gt.global_position.x)
		min_pos.z = min(min_pos.z, gt.global_position.z)
	return min_pos

func _get_half_height(node: Node) -> float:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh:
			var aabb: AABB = child.mesh.get_aabb()
			return aabb.size.y / 2.0
		var result = _get_half_height(child)
		if result > 0.0:
			return result
	return 0.0

func _get_ground_position(mouse_pos: Vector2):
	var origin := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, 0.0)
	return plane.intersects_ray(origin, dir)

func _strip_to_base_tile(root: Node3D) -> void:
	var base := _find_base_tile_node(root)
	if base == null or base == root:
		return   # gak ketemu base_tile (atau base_tile-nya root sendiri), biarin apa adanya

	# kumpulin base_tile + semua leluhurnya sampe root -- jalur ini harus dibiarin utuh
	var keep_chain: Array[Node] = []
	var n: Node = base
	while n != null:
		keep_chain.append(n)
		if n == root:
			break
		n = n.get_parent()

	_prune_except(root, base, keep_chain)
	
func _prune_except(node: Node, base: Node3D, keep_chain: Array[Node]) -> void:
	for child in node.get_children():
		if child == base:
			continue   # base_tile & semua anaknya dibiarin utuh
		if keep_chain.has(child):
			_prune_except(child, base, keep_chain)   # node perantara menuju base_tile, turun terus tapi jangan dihapus
		else:
			child.free()   # apapun ini -- decoration, labels, atau grup baru apapun -- buang total

func _apply_native_transparency(node: Node, alpha: float) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			child.transparency = 1.0 - alpha   # transparency: 0=opaque, 1=full transparan (kebalikan dari alpha)
		_apply_native_transparency(child, alpha)

#func _set_ghost_transparent(node: Node, alpha: float) -> void:
	#for child in node.get_children():
		#if child is MeshInstance3D:
			#var original_color := Color(1, 1, 1)
			#if child.get_surface_override_material(0):
				#original_color = child.get_surface_override_material(0).albedo_color
			#elif child.mesh and child.mesh.surface_get_material(0):
				#original_color = child.mesh.surface_get_material(0).albedo_color
#
			#var mat := StandardMaterial3D.new()
			#mat.albedo_color = Color(original_color.r, original_color.g, original_color.b, alpha)
			#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			#child.material_override = mat
			#child.set_meta("ghost_mat", mat)
			#child.set_meta("ghost_base_color", original_color)
			#child.set_meta("ghost_alpha", alpha)
		#_set_ghost_transparent(child, alpha)

#func _tint_ghost(node: Node3D, invalid: bool) -> void:
	#if node == null:
		#return
	#_apply_tint(node, invalid)
func _make_flat_shadow(node: Node, alpha: float) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(valid_color.r, valid_color.g, valid_color.b, alpha)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			child.material_override = mat
			child.set_meta("shadow_mat", mat)
			child.set_meta("shadow_alpha", alpha)
		_make_flat_shadow(child, alpha)

func _tint_shadow(node: Node, invalid: bool) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.has_meta("shadow_mat"):
			var alpha: float = child.get_meta("shadow_alpha")
			var color: Color = invalid_color if invalid else valid_color
			child.get_meta("shadow_mat").albedo_color = Color(color.r, color.g, color.b, alpha)
		_tint_shadow(child, invalid)

#func _apply_tint(node: Node, invalid: bool) -> void:
	#for child in node.get_children():
		#if child is MeshInstance3D and child.has_meta("ghost_mat"):
			#var alpha: float = child.get_meta("ghost_alpha")
			#if invalid:
				#child.get_meta("ghost_mat").albedo_color = Color(invalid_color.r, invalid_color.g, invalid_color.b, alpha)
			#elif use_original_color_when_valid:
				#var base: Color = child.get_meta("ghost_base_color")
				#child.get_meta("ghost_mat").albedo_color = Color(base.r, base.g, base.b, alpha)
			#else:
				#child.get_meta("ghost_mat").albedo_color = Color(valid_color.r, valid_color.g, valid_color.b, alpha)
		#_apply_tint(child, invalid)

func _clear_ghost() -> void:
	if ghost_float:
		ghost_float.queue_free()
		ghost_float = null
	if ghost_indicator:
		ghost_indicator.queue_free()
		ghost_indicator = null

func remove_tile_from_grid(tile: Node3D) -> void:
	if not placement_data.has(tile):
		return
		
	var data: Dictionary = placement_data[tile]
	for offset in data.shape:
		var c: Vector2i = data.anchor + offset
		if grid.has(c):
			grid[c].clear()
			
	placement_data.erase(tile)
	tile.queue_free()
