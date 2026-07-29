extends Node

signal turn_changed(turn: int, season: int, year: int)
signal stage_changed(stage: int)
signal budget_changed(budget: int)
signal stats_changed()
signal interaction_requested(interaction_type: String, tile_data: Dictionary)

enum Season { SPRING, SUMMER, FALL, WINTER }

var current_stage: int = 0
var budget: int = 50000
var current_location: FarmLocation
var batches: Dictionary = {}

var active_tiles: Array[Dictionary] = []
var batch_flags: Dictionary = {}
signal batch_flag_unlocked(flag_name: String) # { "tile": Node3D, "data": CardData, "remaining_duration": int, "label": Label3D }


func _ready() -> void:
	current_location = FarmLocation.new()
	
	_create_new_batch(2025)
	
func _create_new_batch(year: int) -> void:
	var b = CoffeeBatch.new()
	b.batch_year = year
	b.aroma = current_location.base_aroma
	b.body = current_location.base_body
	b.acidity = current_location.base_acidity
	b.sweetness = current_location.base_sweetness
	b.complexity = current_location.base_complexity
	b.aftertaste = current_location.base_aftertaste
	b.moisture = current_location.base_moisture
	b.defect_rate = current_location.base_defect_rate
	b.cherry_kg = current_location.base_yield
	batches[year] = b
	
func get_active_farm_batch() -> CoffeeBatch:
	if not batches.has(TimeManager.year):
		_create_new_batch(TimeManager.year)
	return batches[TimeManager.year]
	
func get_oldest_ready_batch(process_id: String) -> CoffeeBatch:
	# Jika process_id berawalan FP (Farm Phase)
	if process_id.begins_with("FP"):
		return get_active_farm_batch()
		
	# Jika post-harvest (Roasting, dst), cari batch tertua yang siap
	# Tapi user bilang: "saat ini dibuat keduanya keluar dulu saja" 
	# Jadi sementara kita pakai get_active_farm_batch() atau batch yang umurnya paling muda jika belum ada requirement ketat
	# Sesuai komentar user: "kondisi koding saat ini hanya bisa menampilkan stat batch terakhir aja... saat ini dibuat keduanya keluar dulu saja"
	# Untuk memudahkan, kita panggil batch terakhir yang ditanam (current_year) atau yang paling tua.
	
	var oldest_year = 9999
	var target_batch: CoffeeBatch = null
	for y in batches.keys():
		var b = batches[y]
		# Asumsikan kalau mau diproses lebih lanjut, minimal sudah lewat FP04 (Harvest)
		if b.completed_processes.has("FP04") and not b.completed_processes.has(process_id):
			if y < oldest_year:
				oldest_year = y
				target_batch = b
				
	if target_batch:
		return target_batch
		
	return get_active_farm_batch()
	
func register_placed_tile(tile_node: Node3D, card_data: CardData, extra_data: Dictionary = {}) -> void:
	if card_data == null:
		return
		
	var label = _find_turn_label(tile_node)
	if label:
		label.text = str(card_data.duration)
		
	var name_label = _find_lahan_name_label(tile_node)
	if name_label and current_location:
		name_label.text = current_location.location_name
		
	var tile_dict = {
		"tile": tile_node,
		"data": card_data,
		"remaining_duration": card_data.duration,
		"label": label,
		"paid": false,
		"ready": false
	}
	tile_dict.merge(extra_data)
	active_tiles.append(tile_dict)


func unregister_placed_tile(tile_node: Node3D) -> void:
	for i in range(active_tiles.size() - 1, -1, -1):
		if active_tiles[i].tile == tile_node:
			active_tiles.remove_at(i)
			break


func _find_turn_label(node: Node) -> Label3D:
	for child in node.get_children():
		if child is Label3D and child.name == "turn":
			return child
		var found = _find_turn_label(child)
		if found: return found
	return null

func _find_lahan_name_label(node: Node) -> Label3D:
	for child in node.get_children():
		if child is Label3D and child.name == "lahan":
			return child
		var found = _find_lahan_name_label(child)
		if found: return found
	return null

func advance_turn() -> void:
	TimeManager.advance_turn()
	
	# Update active tiles and lock them
	for i in range(active_tiles.size() - 1, -1, -1):
		var tile_dict = active_tiles[i]
		
		# Deduct cost if not yet paid (placed this turn)
		if not tile_dict.paid:
			tile_dict.paid = true
			budget -= tile_dict.data.cost
			budget_changed.emit(budget)
			
		# Lock the tile if it's not locked yet
		if tile_dict.tile and is_instance_valid(tile_dict.tile) and not tile_dict.tile.has_meta("locked"):
			tile_dict.tile.set_meta("locked", true)
			
		if tile_dict.ready:
			continue # Already ready for interaction, don't tick duration
			
		tile_dict.remaining_duration -= 1
		
		if tile_dict.label and is_instance_valid(tile_dict.label):
			tile_dict.label.text = str(max(0, tile_dict.remaining_duration))
			
		if tile_dict.remaining_duration <= 0:
			if tile_dict.data.requires_interaction:
				tile_dict.ready = true
				if tile_dict.label and is_instance_valid(tile_dict.label):
					tile_dict.label.text = "!"
					tile_dict.label.modulate = Color(1.0, 1.0, 0.0) # Highlight yellow
			else:
				# Apply effects immediately for normal cards
				var target_b = get_oldest_ready_batch(tile_dict.data.process_id)
				target_b.apply_effects(tile_dict)
				stats_changed.emit()
				if tile_dict.tile and is_instance_valid(tile_dict.tile):
					PlacementManager.remove_tile_from_grid(tile_dict.tile)
					
				# Remove from active ticking list
				active_tiles.remove_at(i)
				
	turn_changed.emit(TimeManager.turn_in_year, TimeManager.season, TimeManager.year)
	_check_stage_progression()

func is_tile_ready_for_interaction(tile_node: Node3D) -> bool:
	for dict in active_tiles:
		if dict.tile == tile_node and dict.ready:
			return true
	return false

func trigger_interaction(tile_node: Node3D) -> void:
	for dict in active_tiles:
		if dict.tile == tile_node and dict.ready:
			interaction_requested.emit(dict.data.interaction_type, dict)
			return

func resolve_interaction(tile_dict: Dictionary, process_next: bool) -> void:
	# Remove from active_tiles
	var index = active_tiles.find(tile_dict)
	if index != -1:
		active_tiles.remove_at(index)
	var target_b = get_oldest_ready_batch(tile_dict.data.process_id)
	target_b.apply_effects(tile_dict)
	if tile_dict.tile and is_instance_valid(tile_dict.tile):
		PlacementManager.remove_tile_from_grid(tile_dict.tile)
		
	if tile_dict.data.interaction_type == "ROASTING":
		batch_flags["after_roasting"] = true
		batch_flag_unlocked.emit("after_roasting")
	elif tile_dict.data.interaction_type == "TESTING":
		batch_flags["after_testing"] = true
		batch_flag_unlocked.emit("after_testing")
		
	if process_next:
		stats_changed.emit()
	else:
		# Sell logic: convert yield to budget
		var income = (target_b.cherry_kg * 10) + (target_b.aroma * 5)
		budget += income
		budget_changed.emit(budget)

		# Reset batch as it is sold
		if batches.has(target_b.batch_year):
			batches.erase(target_b.batch_year)
			
		stats_changed.emit()

func _check_stage_progression() -> void:
	# Define stage mapping according to GDD
	var turn_in_year = TimeManager.turn_in_year
	var next_stage = current_stage
	
	if turn_in_year == 1:
		next_stage = 0
		if not batches.has(TimeManager.year):
			_create_new_batch(TimeManager.year)
	elif turn_in_year == 3: next_stage = 1
	elif turn_in_year == 6: next_stage = 2
	elif turn_in_year == 8: next_stage = 3
	elif turn_in_year == 11: next_stage = 4
	elif turn_in_year == 13: next_stage = 5
	# Stage 6, 7, 8 happen after Roasting, handled separately or via UI
	
	if next_stage != current_stage:
		current_stage = next_stage
		stage_changed.emit(current_stage)
		
func is_tile_locked(tile_node: Node3D) -> bool:
	return tile_node.has_meta("locked") and tile_node.get_meta("locked") == true
