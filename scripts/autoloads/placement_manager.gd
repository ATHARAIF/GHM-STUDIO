extends Node


@export_group("Animation")
## Tinggi objek melayang (bayangan) dari atas tanah saat ditarik (meter).
@export var float_height: float = 0.4
## Durasi animasi jatuhnya objek dari melayang sampai menyentuh tanah (detik).
@export var place_duration: float = 0.35

@onready var ghost_visualizer = $GhostVisualizer

var camera: Camera3D
var current_tile_scene: PackedScene
var current_base_shape: Array[Vector2i] = [Vector2i.ZERO]
var current_shape: Array[Vector2i] = [Vector2i.ZERO]
var rotation_steps: int = 0
var ghost_visual_rotation: float = 0.0

var ground_tiles: Array[GroundTile] = []
var grid: Dictionary = {}          # Vector2i -> GroundTile
var cell_size: float = 2.0
var grid_origin: Vector3 = Vector3.ZERO

var ground_top_offset: float = 0.0
var tile_bottom_offset: float = 0.0

var placement_data: Dictionary = {}   # tile_instance (Node3D) -> {scene, base_shape, shape, anchor, rotation_steps, card_node}

var current_card_node: Control = null   # referensi LANGSUNG ke node Card asli yang lagi di-drag (bukan path/scene)
var pending_interaction_tile: Node3D = null
var moving_tile: Node3D = null
var original_move_data: Dictionary = {}
var drag_dummy_card: Control = null

func _ready() -> void:
	set_process(false)
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.connect(_on_interaction_confirmed)
		em.card_placement_interaction_cancelled.connect(_on_interaction_cancelled)

# region Core System & Input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if current_tile_scene == null and moving_tile == null:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_try_pickup(event.position, false)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_try_pickup(event.position, true)

func _try_pickup(mouse_pos: Vector2, instant_cancel: bool = false) -> void:
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

	# (We no longer abort if card_node is null. The CardHand will auto-spawn it because of stats_changed.emit())

	if instant_cancel:
		if card_node and is_instance_valid(card_node) and card_node.has_method("set"):
			card_node.set("is_placed", false)
			var op = card_node.get("origin_parent")
			if op and op.has_method("set_card_played") and data.has("card_data"):
				op.set_card_played(data["card_data"], false)
				
		StageManager.unregister_placed_tile(tile)
		placement_data.erase(tile)
		for offset in data.shape:
			var c: Vector2i = data.anchor + offset
			if grid.has(c):
				grid[c].clear()
		tile.queue_free()
		
		if card_node and is_instance_valid(card_node) and card_node.has_method("set"):
			card_node.show()
			card_node.set("top_level", true)
			var op = card_node.get("origin_parent")
			var oi = card_node.get("origin_index")
			if op:
				op.move_child(card_node, oi)
			var card_size = card_node.get("size")
			if card_size:
				card_node.call("animate_return_from", get_viewport().get_mouse_position() - (card_size / 2.0))
			else:
				card_node.call("animate_return_from", get_viewport().get_mouse_position())
		elif data.has("card_data"):
			# If restored from memory, card_node is null. Find the newly spawned card and animate it!
			var card_data = data["card_data"]
			var ch = null
			var hands = get_tree().current_scene.find_children("card_hand", "", true, false)
			for hand in hands:
				if hand.is_visible_in_tree():
					ch = hand
					break
			if not ch: ch = get_node_or_null("/root/MainHUD/card_hand")
			if ch:
				for c in ch.get_children():
					print("Checking child: ", c.name)
					if c.get("card_data") == card_data and not c.get("is_placed"):
						print("FOUND MATCHING CARD! Animating.")
						var card_size = c.get("size")
						if card_size:
							c.call("animate_return_from", get_viewport().get_mouse_position() - (card_size / 2.0))
						else:
							c.call("animate_return_from", get_viewport().get_mouse_position())
						break
	else:
		_begin_move_tile(tile, data)

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

# endregion

# region Drag & Drop State
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

	var start_rot := ghost_visual_rotation
	ghost_visual_rotation += 90.0
	var target_rot := ghost_visual_rotation

	ghost_visualizer.animate_rotation(start_rot, target_rot)



func _rotate_shape(shape: Array[Vector2i], steps: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = shape.duplicate()
	for i in steps:
		var rotated: Array[Vector2i] = []
		for cell in result:
			rotated.append(Vector2i(cell.y, -cell.x))   # match arah rotation_degrees.y bawaan Godot
		result = rotated
	return result


func _begin_move_tile(tile: Node3D, data: Dictionary) -> void:
	moving_tile = tile
	original_move_data = data.duplicate()
	
	for offset in data.shape:
		var c: Vector2i = data.anchor + offset
		if grid.has(c):
			grid[c].clear()
			
	tile.hide()
	
	current_tile_scene = data.scene
	current_base_shape = data.base_shape.duplicate()
	rotation_steps = data.rotation_steps
	ghost_visual_rotation = float(rotation_steps) * 90.0
	current_shape = _rotate_shape(current_base_shape, rotation_steps)
	
	if data.has("card_data"):
		var ch = null
		var hands = get_tree().current_scene.find_children("card_hand", "", true, false)
		for hand in hands:
			if hand.is_visible_in_tree():
				ch = hand
				break
		if not ch: ch = get_node_or_null("/root/MainHUD/card_hand")
		if ch and ch.get("card_scene"):
			drag_dummy_card = ch.card_scene.instantiate()
			drag_dummy_card.set("card_data", data["card_data"])
			drag_dummy_card.top_level = true
			drag_dummy_card.hide()
			drag_dummy_card.set_process(false)
			drag_dummy_card.set_process_unhandled_input(false)
			ch.add_child(drag_dummy_card)
	
	set_process(true)

func _process(delta: float) -> void:
	if not moving_tile:
		set_process(false)
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	
	var is_outside_hand = true
	var hand_rect = Rect2()
	
	# Find the VISIBLE card_hand, because there might be a hidden one (footer1)
	var ch = null
	var hands = get_tree().current_scene.find_children("card_hand", "", true, false)
	for hand in hands:
		if hand.is_visible_in_tree():
			ch = hand
			break
			
	if not ch: ch = get_node_or_null("/root/MainHUD/card_hand")
	
	if ch:
		hand_rect = ch.get_global_rect()
		is_outside_hand = not hand_rect.has_point(mouse_pos)
		
	if is_outside_hand:
		update_ghost(mouse_pos)
		if drag_dummy_card:
			if drag_dummy_card.visible and drag_dummy_card.modulate.a > 0:
				drag_dummy_card.hide()
				drag_dummy_card.modulate.a = 0.0
	else:
		_clear_ghost()
		if drag_dummy_card:
			if not drag_dummy_card.visible or drag_dummy_card.modulate.a == 0.0:
				drag_dummy_card.show()
				drag_dummy_card.modulate.a = 0.0
				var tw = create_tween()
				tw.tween_property(drag_dummy_card, "modulate:a", 1.0, 0.15)
			var s = drag_dummy_card.get("size")
			if s: drag_dummy_card.global_position = mouse_pos - (s / 2.0)
			else: drag_dummy_card.global_position = mouse_pos
	
	if Input.is_action_just_pressed("rotate"):
		rotate_ghost()
		
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if is_outside_hand:
			_try_place_move(mouse_pos)
		else:
			_cancel_move()

func _try_place_move(mouse_pos: Vector2) -> void:
	var world_pos = _get_ground_position(mouse_pos)
	_clear_ghost()
	set_process(false)
	
	if world_pos == null:
		_cancel_move(true)
		return
		
	var shape := current_shape
	var anchor_coord := _world_to_grid(world_pos)
	
	if not _can_place(anchor_coord, shape):
		_cancel_move(true)
		return
		
	var anchor_tile: GroundTile = grid[anchor_coord]
	var final_pos = anchor_tile.global_position
	final_pos.y += ground_top_offset + tile_bottom_offset
	moving_tile.rotation_degrees.y = rotation_steps * 90.0
	
	var start_pos = final_pos
	start_pos.y += float_height
	moving_tile.global_position = start_pos
	moving_tile.show()
	
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BOUNCE)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(moving_tile, "global_position", final_pos, place_duration)
	
	for offset in shape:
		var coord = anchor_coord + offset
		grid[coord].occupy(moving_tile)
		
	var data = placement_data[moving_tile]
	data["anchor"] = anchor_coord
	data["shape"] = shape.duplicate()
	data["rotation_steps"] = rotation_steps
	
	moving_tile = null
	if drag_dummy_card:
		drag_dummy_card.queue_free()
		drag_dummy_card = null
	original_move_data.clear()
	current_tile_scene = null

func _cancel_move(skip_clear_ghost: bool = false) -> void:
	if not skip_clear_ghost:
		_clear_ghost()
	set_process(false)
	
	var card = original_move_data.get("card_node", null)
	
	if card and is_instance_valid(card):
		if card.has_method("set"):
			card.set("is_placed", false)
			var op = card.get("origin_parent")
			if op and op.has_method("set_card_played") and original_move_data.has("card_data"):
				op.set_card_played(original_move_data["card_data"], false)
	
	StageManager.unregister_placed_tile(moving_tile)
	if placement_data.has(moving_tile):
		placement_data.erase(moving_tile)
	moving_tile.queue_free()
	
	if card and is_instance_valid(card):
		if card.has_method("set"):
			card.show()
			card.set("top_level", true)
			var op = card.get("origin_parent")
			var oi = card.get("origin_index")
			if op:
				op.move_child(card, oi)
			var mouse_pos = get_viewport().get_mouse_position()
			var card_size = card.get("size")
			if card_size:
				card.call("animate_return_from", mouse_pos - (card_size / 2.0))
			else:
				card.call("animate_return_from", mouse_pos)
	elif original_move_data.has("card_data"):
		var card_data = original_move_data["card_data"]
		var ch = null
		var hands = get_tree().current_scene.find_children("card_hand", "", true, false)
		for hand in hands:
			if hand.is_visible_in_tree():
				ch = hand
				break
		if not ch: ch = get_node_or_null("/root/MainHUD/card_hand")
		if ch:
			for c in ch.get_children():
				if c.get("card_data") == card_data and not c.get("is_placed"):
					var mouse_pos = get_viewport().get_mouse_position()
					var card_size = c.get("size")
					if card_size:
						c.call("animate_return_from", mouse_pos - (card_size / 2.0))
					else:
						c.call("animate_return_from", mouse_pos)
					break
			
	moving_tile = null
	if drag_dummy_card:
		drag_dummy_card.queue_free()
		drag_dummy_card = null
	original_move_data.clear()
	current_tile_scene = null

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

	var anchor_coord := _world_to_grid(world_pos)
	var valid := _can_place(anchor_coord, current_shape)

	var base_pos: Vector3
	if valid:
		var anchor_tile: GroundTile = grid[anchor_coord]
		base_pos = anchor_tile.global_position
	else:
		base_pos = world_pos
	
	base_pos.y += ground_top_offset + tile_bottom_offset
	var indicator_pos = base_pos
	
	var float_pos := base_pos
	float_pos.y += float_height
	
	ghost_visualizer.update_ghost(current_tile_scene, rotation_steps, ghost_visual_rotation, float_pos, indicator_pos, valid)

# endregion

# region Placement & Interaction
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
	if current_card_node and current_card_node.get("target_batch_year") != null:
		placement_data[tile]["target_batch_year"] = current_card_node.get("target_batch_year")
	
	if card_data != null:
		print("Card data has_config_popup: ", card_data.get("has_config_popup"))
		if card_data.get("has_config_popup"):
			pending_interaction_tile = tile
			if has_node("/root/EventManager"):
				print("Emitting interaction request for ", card_data.card_name)
				var em = get_node("/root/EventManager")
				em.card_placement_interaction_requested.emit(card_data.card_name, tile, card_data)
			else:
				print("EventManager singleton not found!")
		else:
			print("No interaction requested, registering tile directly.")
			StageManager.register_placed_tile(tile, card_data, placement_data[tile])

	current_tile_scene = null   # reset, biar pickup detection ("current_tile_scene == null") gak ke-block
	current_card_node = null

	return true

func _on_interaction_confirmed(card_name: String, tile: Node3D, card_data: Resource, extra_data: Dictionary) -> void:
	if pending_interaction_tile == tile and placement_data.has(tile):
		var data = placement_data[tile]
		for key in extra_data:
			data[key] = extra_data[key]
		# Pass data instead of extra_data so target_batch_year is included
		StageManager.register_placed_tile(tile, data["card_data"], data)
	if pending_interaction_tile == tile:
		pending_interaction_tile = null

func _on_interaction_cancelled(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if pending_interaction_tile == tile and placement_data.has(tile):
		var data = placement_data[tile]
		var card = data.get("card_node", null)
		
		# Free occupied cells
		for offset in data.shape:
			var c: Vector2i = data.anchor + offset
			if grid.has(c):
				grid[c].clear()
				
		placement_data.erase(tile)
		tile.queue_free()
		
		# Return card to hand using the card's native animation logic
		if card and is_instance_valid(card):
			if card.has_method("set"):
				card.set("is_placed", false)
				card.show()
				card.set("top_level", true)
				var op = card.get("origin_parent")
				if op and op.has_method("set_card_played") and data.has("card_data"):
					op.set_card_played(data["card_data"], false)
				var oi = card.get("origin_index")
				if op:
					op.move_child(card, oi)
				card.call("animate_return_from", card.global_position)
				
	if pending_interaction_tile == tile:
		pending_interaction_tile = null

# endregion

# region Grid & Shape Math
func _can_place(anchor_coord: Vector2i, shape: Array[Vector2i]) -> bool:
	for offset in shape:
		var coord = anchor_coord + offset
		if not grid.has(coord):
			return false          # cell di luar area ground
		var gt: GroundTile = grid[coord]
		if gt.is_occupied or gt.is_locked:
			return false          # cell udah ketiban tile lain atau masih terkunci
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
		if child.name == "base_tiles" and child is Node3D:
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

# endregion

# region Ghost Visual Rendering
# Delegated to ghost_visualizer.gd
# endregion

# region Cleanup
func _clear_ghost() -> void:
	ghost_visualizer.clear_ghost()

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
# endregion

# ==========================================
# RESTORE STATE HELPER (Untuk Opsi A)
# ==========================================
func reoccupy_grid_for_restored_tile(tile: Node3D, data: CardData) -> void:
	if not tile or not data: return
	
	var anchor_coord := _world_to_grid(tile.global_position)
	var rot_steps = int(round(tile.rotation_degrees.y / 90.0))
	var base_shape = _get_shape(data.tile_scene)
	var shape = _rotate_shape(base_shape, rot_steps)
	
	placement_data[tile] = {
		"scene": data.tile_scene,
		"base_shape": base_shape.duplicate(),
		"shape": shape.duplicate(),
		"anchor": anchor_coord,
		"rotation_steps": rot_steps,
		"card_node": null,
		"card_data": data
	}
	
	for offset in shape:
		var coord = anchor_coord + offset
		if grid.has(coord):
			grid[coord].occupy(tile)
