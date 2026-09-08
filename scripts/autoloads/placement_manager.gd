extends Node


@export_group("Animation")
## Tinggi objek melayang (bayangan) dari atas tanah saat ditarik (meter).
@export var float_height: float = 0.4
## Durasi animasi jatuhnya objek dari melayang sampai menyentuh tanah (detik).
@export var place_duration: float = 0.35

@export_group("Shine Effect")
@export var shine_material: ShaderMaterial   # drag ShaderMaterial yg pake 3d_item_highlighter.gdshader ke sini
@export var shine_duration_override: float = 0.0   # 0 = auto-hitung dari uniform shader (shine_width, shine_speed, cycle_interval)
@export_range(1, 10) var shine_repeat_count: int = 1   # berapa kali sapuan shine muncul (dipake kalau shine_duration_override == 0)
@export_range(0.0, 1.0) var shine_trigger_ratio: float = 0.55   # kapan shine mulai, relatif ke place_duration (0 = pas mulai jatuh, 1 = pas landing)

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
var highlighted_farm_tiles: Array[Node3D] = []

var ground_top_offset: float = 0.0
var tile_bottom_offset: float = 0.0

var placement_data: Dictionary = {}   # tile_instance (Node3D) -> {scene, base_shape, shape, anchor, rotation_steps, card_node}

var current_card_node: Control = null   # referensi LANGSUNG ke node Card asli yang lagi di-drag (bukan path/scene)
var pending_interaction_tile: Node3D = null
var moving_tile: Node3D = null
var original_move_data: Dictionary = {}
var drag_dummy_card: Control = null
var grab_offset: Vector2i = Vector2i.ZERO

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
	print("TRY_PICKUP DIPANGGIL DI POSISI MOUSE: ", mouse_pos)
	var tile: Node3D = null
	
	if camera:
		var origin := camera.project_ray_origin(mouse_pos)
		var dir := camera.project_ray_normal(mouse_pos)
		var space_state = camera.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(origin, origin + dir * 1000.0)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query)
		if result:
			print("Physics raycast hit: ", result.collider.name)
			var node = result.collider
			while node != null:
				if placement_data.has(node):
					tile = node
					print("Found valid machine tile via physics: ", tile.name)
					break
				node = node.get_parent()

	if tile == null:
		var world_pos = _get_ground_position(mouse_pos)
		if world_pos == null: return
		var coord := _world_to_grid(world_pos)
		if not grid.has(coord): return
		var gt: GroundTile = grid[coord]
		if not gt.is_occupied: return
		tile = gt.placed_tile
		
	if not tile or not placement_data.has(tile):
		return   # data gak ketemu, aman-in aja gak diapa-apain
		
	if StageManager.is_tile_ready_for_interaction(tile):
		StageManager.trigger_interaction(tile)
		return
		
	if StageManager.is_tile_locked(tile):
		return   # sudah dikunci oleh StageManager (sudah end turn)

	var data: Dictionary = placement_data[tile]
	
	var raw_node = data.get("card_node")
	var card_node: Control = null
	if is_instance_valid(raw_node):
		card_node = raw_node as Control

	# Simpan offset berdasarkan ubin mana yang diklik pemain vs titik nol bendanya
	var click_coord = data.anchor
	var world_pos = _get_ground_position(mouse_pos)
	if world_pos != null:
		var c = _world_to_grid(world_pos)
		if grid.has(c) and grid[c].is_occupied and grid[c].placed_tile == tile:
			click_coord = c
			
	grab_offset = click_coord - data.anchor

	# (We no longer abort if card_node is null. The CardHand will auto-spawn it because of stats_changed.emit())

	if instant_cancel:
		if data.get("card_data") is ItemData:
			print("Mesin tidak bisa dikembalikan ke tangan dengan klik kanan!")
			return
			
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

	ground_top_offset = _get_top_y(tiles[0])
	cell_size = _detect_cell_size(tiles)
	grid_origin = _find_min_corner(tiles)

	grid.clear()
	placement_data.clear()
	for gt in tiles:
		var coord := _world_to_grid(gt.global_position)
		gt.grid_coord = coord
		grid[coord] = gt

var shape_cache: Dictionary = {}   # PackedScene -> Array[Vector2i], biar gak itung ulang tiap drag

# endregion

# region Drag & Drop State
func begin_drag(tile_scene: PackedScene, card_node: Control = null, initial_rotation_steps: int = 0) -> void:
	grab_offset = Vector2i.ZERO
	current_tile_scene = tile_scene
	current_card_node = card_node
	current_base_shape = _get_shape(tile_scene)
	rotation_steps = initial_rotation_steps
	ghost_visual_rotation = float(initial_rotation_steps) * 90.0
	current_shape = _rotate_shape(current_base_shape, rotation_steps)
	var temp = tile_scene.instantiate()
	tile_bottom_offset = _get_bottom_y(temp)
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
	# Normalize steps ke range 0-3 (misal -1 jadi 3, -2 jadi 2)
	var normalized_steps = ((steps % 4) + 4) % 4
	for i in normalized_steps:
		var rotated: Array[Vector2i] = []
		for cell in result:
			rotated.append(Vector2i(cell.y, -cell.x))   # match arah rotation_degrees.y bawaan Godot
		result = rotated
	return result


func _begin_move_tile(tile: Node3D, data: Dictionary) -> void:
	toggle_farm_highlight(true)
	moving_tile = tile
	original_move_data = data.duplicate()
	tile_bottom_offset = _get_bottom_y(tile)
	
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
	
	if data.get("card_data") is CardData:
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
		ghost_visualizer.fade_out_and_clear()
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
	var raw_coord := _world_to_grid(world_pos)
	var anchor_coord := raw_coord - grab_offset
	
	if not _is_shape_within_bounds(anchor_coord, shape):
		# Coba cari tile terdekat yang valid secara BORDER
		var closest_tile = null
		var min_dist = INF
		for gt in ground_tiles:
			if _is_shape_within_bounds(gt.grid_coord, shape):
				var dist = Vector2(gt.grid_coord.x, gt.grid_coord.y).distance_squared_to(Vector2(anchor_coord.x, anchor_coord.y))
				if dist < min_dist:
					min_dist = dist
					closest_tile = gt
		
		if closest_tile:
			anchor_coord = closest_tile.grid_coord
		else:
			_cancel_move(true)
			return
			
	if not _can_place(anchor_coord, shape):
		_cancel_move(true)
		return
		
	var anchor_tile: GroundTile = grid[anchor_coord]
	var final_pos = anchor_tile.global_position
	final_pos.y += ground_top_offset - tile_bottom_offset
	moving_tile.rotation_degrees.y = rotation_steps * 90.0
	
	var start_pos = final_pos
	start_pos.y += float_height
	moving_tile.global_position = start_pos
	moving_tile.show()
	
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BOUNCE)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(moving_tile, "global_position", final_pos, place_duration)
	tw.tween_callback(_play_shine_effect.bind(moving_tile)).set_delay(place_duration * shine_trigger_ratio)
	
	for offset in shape:
		var coord = anchor_coord + offset
		grid[coord].occupy(moving_tile)
		
	var data = placement_data[moving_tile]
	data["anchor"] = anchor_coord
	data["shape"] = shape.duplicate()
	data["rotation_steps"] = rotation_steps
	
	var item_data = data.get("card_data")
	if item_data is ItemData:
		for m_id in FactoryManager.placed_machines:
			if FactoryManager.placed_machines[m_id]["data"] == item_data:
				FactoryManager.placed_machines[m_id]["position"] = final_pos
				break
	
	moving_tile = null
	if drag_dummy_card:
		drag_dummy_card.queue_free()
		drag_dummy_card = null
	if not original_move_data.is_empty():
		toggle_farm_highlight(false)
	original_move_data.clear()
	current_tile_scene = null

func _cancel_move(skip_clear_ghost: bool = false) -> void:
	if not skip_clear_ghost:
		ghost_visualizer.fade_out_and_clear()
	set_process(false)
	
	var card = original_move_data.get("card_node", null)
	
	if card and is_instance_valid(card):
		if card.has_method("set"):
			card.set("is_placed", false)
			var op = card.get("origin_parent")
			if op and op.has_method("set_card_played") and original_move_data.has("card_data"):
				op.set_card_played(original_move_data["card_data"], false)
	
	var is_item = original_move_data.get("card_data") is ItemData
	
	var temp_tile = moving_tile
	moving_tile = null
	
	if drag_dummy_card:
		drag_dummy_card.queue_free()
		drag_dummy_card = null
		
	if not is_item:
		if temp_tile:
			StageManager.unregister_placed_tile(temp_tile)
			if placement_data.has(temp_tile):
				placement_data.erase(temp_tile)
			temp_tile.queue_free()
	else:
		if temp_tile:
			# Kembalikan mesin ke posisi semula
			var anchor = original_move_data["anchor"]
			for offset in original_move_data["shape"]:
				var c = anchor + offset
				if grid.has(c):
					grid[c].occupy(temp_tile)
			temp_tile.show()
			
			var final_pos = grid[anchor].global_position
			final_pos.y += ground_top_offset - tile_bottom_offset
			temp_tile.global_position = final_pos
			temp_tile.rotation_degrees.y = original_move_data["rotation_steps"] * 90.0
		
		# Jangan di queue_free(), biarkan dia di placement_data
	
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
			
	if not original_move_data.is_empty():
		toggle_farm_highlight(false)
	original_move_data.clear()
	current_tile_scene = null

func end_drag() -> void:
	ghost_visualizer.fade_out_and_clear()
	current_tile_scene = null
	current_card_node = null

func cancel_ghost() -> void:
	ghost_visualizer.fade_out_and_clear()

func update_ghost(mouse_pos: Vector2) -> void:
	if camera == null or current_tile_scene == null:
		return

	var world_pos = _get_ground_position(mouse_pos)
	if world_pos == null:
		return

	# Dapatkan koordinat awal berdasarkan mouse, lalu kurangi dengan grab_offset
	# agar titik pusat benda bergeser sesuai dengan titik pegangan mouse.
	var raw_coord := _world_to_grid(world_pos)
	var anchor_coord := raw_coord - grab_offset
	var base_pos: Vector3 = world_pos
	
	# === LOGIKA SNAP CERDAS KE PAPAN ===
	# Kita harus memastikan SELURUH bagian benda (bukan cuma titik pivotnya)
	# berada di dalam papan. Jadi kita cari tile terdekat yang 'valid' secara BORDER (bukan occupancy).
	var within_bounds := _is_shape_within_bounds(anchor_coord, current_shape)
	
	if within_bounds:
		# Jika posisi mouse saat ini valid di dalam papan, langsung snap ke sana
		base_pos = grid[anchor_coord].global_position
	else:
		# Jika posisi mouse membuat benda keluar jalur,
		# cari tile terdekat di mana benda tersebut BISA muat 100% di dalam papan.
		var closest_tile = null
		var min_dist = INF
		
		for gt in ground_tiles:
			if _is_shape_within_bounds(gt.grid_coord, current_shape):
				# Hitung jarak berdasarkan koordinat grid, bukan posisi global
				var dist = Vector2(gt.grid_coord.x, gt.grid_coord.y).distance_squared_to(Vector2(anchor_coord.x, anchor_coord.y))
				if dist < min_dist:
					min_dist = dist
					closest_tile = gt
					
		if closest_tile:
			base_pos = closest_tile.global_position
			anchor_coord = closest_tile.grid_coord
		else:
			# Fallback: jika papan terlalu kecil untuk menampung benda ini sama sekali
			if grid.has(anchor_coord):
				base_pos = grid[anchor_coord].global_position
			
	var valid := _can_place(anchor_coord, current_shape)
	
	base_pos.y += ground_top_offset - tile_bottom_offset
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
	var raw_coord := _world_to_grid(world_pos)
	var anchor_coord := raw_coord - grab_offset
	
	if not _is_shape_within_bounds(anchor_coord, shape):
		# Coba cari tile terdekat yang valid secara BORDER
		var closest_tile = null
		var min_dist = INF
		for gt in ground_tiles:
			if _is_shape_within_bounds(gt.grid_coord, shape):
				var dist = Vector2(gt.grid_coord.x, gt.grid_coord.y).distance_squared_to(Vector2(anchor_coord.x, anchor_coord.y))
				if dist < min_dist:
					min_dist = dist
					closest_tile = gt
		
		if closest_tile:
			anchor_coord = closest_tile.grid_coord
		else:
			return false
			
	if not _can_place(anchor_coord, shape):
		return false

	var anchor_tile: GroundTile = grid[anchor_coord]
	var tile := tile_scene.instantiate()
	get_tree().current_scene.add_child(tile)

	var final_pos = anchor_tile.global_position
	final_pos.y += ground_top_offset - tile_bottom_offset
	tile.rotation_degrees.y = rotation_steps * 90.0

	var start_pos = final_pos
	start_pos.y += float_height
	tile.global_position = start_pos

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
		if card_data.get("has_config_popup"):
			tile.hide() # Sembunyikan benda 3D sampai popup dikonfirmasi
			pending_interaction_tile = tile
			if has_node("/root/EventManager"):
				var em = get_node("/root/EventManager")
				em.card_placement_interaction_requested.emit(card_data.card_name, tile, card_data)
		else:
			# Kartu biasa tanpa popup, langsung jalankan animasi jatuh
			var tw := create_tween()
			tw.set_trans(Tween.TRANS_BOUNCE)
			tw.set_ease(Tween.EASE_OUT)
			tw.set_parallel(true)
			tw.tween_property(tile, "global_position", final_pos, place_duration)
			tw.tween_callback(_play_shine_effect.bind(tile)).set_delay(place_duration * shine_trigger_ratio)
			
			StageManager.register_placed_tile(tile, card_data, placement_data[tile])

	current_tile_scene = null   # reset, biar pickup detection ("current_tile_scene == null") gak ke-block
	current_card_node = null

	return true

func _on_interaction_confirmed(card_name: String, tile: Node3D, card_data: Resource, extra_data: Dictionary) -> void:
	if pending_interaction_tile == tile and placement_data.has(tile):
		var data = placement_data[tile]
		for key in extra_data:
			data[key] = extra_data[key]
		
		tile.show() # Munculkan bendanya sekarang
		
		# Animasi Bounce & Shine setelah konfirmasi popup
		var anchor_tile = grid[data["anchor"]]
		var final_pos = anchor_tile.global_position
		final_pos.y += ground_top_offset - tile_bottom_offset
		
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BOUNCE)
		tw.set_ease(Tween.EASE_OUT)
		tw.set_parallel(true)
		tw.tween_property(tile, "global_position", final_pos, place_duration)
		tw.tween_callback(_play_shine_effect.bind(tile)).set_delay(place_duration * shine_trigger_ratio)

		# Daftarkan tile ke sistem
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

func _is_shape_within_bounds(anchor_coord: Vector2i, shape: Array[Vector2i]) -> bool:
	for offset in shape:
		var coord = anchor_coord + offset
		if not grid.has(coord):
			return false          # cell di luar area ground
	return true

func is_cell_valid(coord: Vector2i) -> bool:
	if not grid.has(coord): return false
	var gt: GroundTile = grid[coord]
	if gt.is_occupied or gt.is_locked: return false
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
		if child.name.to_lower() == "base_tiles" and child is Node3D:
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

func _get_local_transform_to(node: Node3D, root: Node3D) -> Transform3D:
	var t = node.transform
	var p = node.get_parent()
	while p and p is Node3D and node != root and p != root:
		t = p.transform * t
		p = p.get_parent()
	if node == root:
		return Transform3D()
	return t

func _get_top_y(root: Node3D) -> float:
	var max_y = -INF
	var meshes = []
	var target = root
	if root.has_node("base_tiles"): target = root.get_node("base_tiles")
	elif root.has_node("tile_ground"): target = root.get_node("tile_ground")
	
	_find_all_meshes(target, meshes)
	if meshes.is_empty(): return 0.0
	for m in meshes:
		var aabb = m.mesh.get_aabb()
		var local_t = _get_local_transform_to(m, root)
		for i in 8:
			var p = aabb.get_endpoint(i)
			var local_p = local_t * p
			if local_p.y > max_y: max_y = local_p.y
	return max_y

func _get_bottom_y(root: Node3D) -> float:
	var min_y = INF
	var meshes = []
	var target = root
	if root.has_node("base_tiles"): target = root.get_node("base_tiles")
	elif root.has_node("tile_ground"): target = root.get_node("tile_ground")
	
	_find_all_meshes(target, meshes)
	if meshes.is_empty(): return 0.0
	for m in meshes:
		var aabb = m.mesh.get_aabb()
		var local_t = _get_local_transform_to(m, root)
		for i in 8:
			var p = aabb.get_endpoint(i)
			var local_p = local_t * p
			if local_p.y < min_y: min_y = local_p.y
	return min_y

func _find_all_meshes(node: Node, arr: Array) -> void:
	if node is Node3D and not node.visible:
		return
	if node is MeshInstance3D and node.mesh:
		arr.append(node)
	
	# We must use find_children with owned=false to get internal GLTF meshes
	for child in node.get_children(true):
		_find_all_meshes(child, arr)

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
func reoccupy_grid_for_restored_tile(tile: Node3D, data: Resource) -> void:
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

# region Shine Effect (one-shot, dipicu setelah bounce selesai)
func _play_shine_effect(tile: Node3D) -> void:
	if shine_material == null or not is_instance_valid(tile):
		return

	var meshes: Array[GeometryInstance3D] = []
	_collect_mesh_instances(tile, meshes)
	if meshes.is_empty():
		return

	# duplicate() biar tiap tile punya instance material sendiri
	var mat := shine_material.duplicate() as ShaderMaterial

	var dir_raw = mat.get_shader_parameter("x_direction")
	var dir_x: float = dir_raw if dir_raw != null else 0.0
	dir_raw = mat.get_shader_parameter("y_direction")
	var dir_y: float = dir_raw if dir_raw != null else 0.0
	dir_raw = mat.get_shader_parameter("z_direction")
	var dir_z: float = dir_raw if dir_raw != null else 1.0
	var shine_dir := Vector3(dir_x, dir_y, dir_z).normalized()

	# Hapus offset -2.5 karena sawtooth shader dari sananya sudah punya titik mulai di period/2 (di luar benda)
	mat.set_shader_parameter("position_offset", -tile.global_position.dot(shine_dir))
	mat.set_shader_parameter("local_time", 0.0)

	for mi in meshes:
		mi.material_overlay = mat

	var duration := shine_duration_override
	var shine_speed_raw = mat.get_shader_parameter("shine_speed")
	var shine_width_raw = mat.get_shader_parameter("shine_width")
	var cycle_interval_raw = mat.get_shader_parameter("cycle_interval")
	var shine_speed: float = shine_speed_raw if shine_speed_raw != null else 1.0
	var shine_width: float = shine_width_raw if shine_width_raw != null else 1.0
	var cycle_interval: float = cycle_interval_raw if cycle_interval_raw != null else 1.0
	
	if duration <= 0.0:
		duration = (shine_width + cycle_interval) / max(shine_speed, 0.001) * shine_repeat_count

	# Gunakan Tween untuk menggerakkan 'local_time' agar tersinkronisasi 100% sempurna
	var tw = create_tween()
	var target_time = duration
	tw.tween_method(func(val: float): 
		if is_instance_valid(mat): mat.set_shader_parameter("local_time", val)
	, 0.0, target_time, duration)

	await get_tree().create_timer(duration).timeout

	if is_instance_valid(tile):
		for mi in meshes:
			if is_instance_valid(mi):
				mi.material_overlay = null

func _collect_mesh_instances(node: Node, out: Array[GeometryInstance3D]) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			out.append(child)
		_collect_mesh_instances(child, out)

var _farm_highlight_refs: int = 0

func toggle_farm_highlight(enable: bool) -> void:
	if enable:
		_farm_highlight_refs += 1
		if _farm_highlight_refs == 1:
			var tiles = get_tree().current_scene.find_children("*FarmInfoTile*", "", true, false)
			for t in tiles:
				if SilhouetteHighlight:
					SilhouetteHighlight.apply_highlight(t, true)
				if not highlighted_farm_tiles.has(t):
					highlighted_farm_tiles.append(t)
	else:
		_farm_highlight_refs = max(0, _farm_highlight_refs - 1)
		if _farm_highlight_refs == 0:
			var tiles = get_tree().current_scene.find_children("*FarmInfoTile*", "", true, false)
			for t in tiles:
				if SilhouetteHighlight:
					SilhouetteHighlight.apply_highlight(t, false)
			highlighted_farm_tiles.clear()

func reset_farm_highlight() -> void:
	_farm_highlight_refs = 0
	highlighted_farm_tiles.clear()

# endregion
