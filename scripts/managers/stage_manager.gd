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
	
	if has_node("/root/TimeManager"):
		get_node("/root/TimeManager").year_changed.connect(_on_year_changed)

func _on_year_changed(new_year: int) -> void:
	if current_location and current_location.current_tree:
		current_location.current_tree.age_years += 1.0
		# Recalculate base stats/yield because age changed
		current_location.current_tree.initialize_from_terroir(current_location)
		
	_create_new_batch(new_year)
	
func _create_new_batch(year: int) -> void:
	var b = CoffeeBatch.new()
	b.batch_year = year
	
	if current_location and current_location.current_tree:
		var tree = current_location.current_tree
		b.aroma = tree.current_aroma
		b.body = tree.current_body
		b.acidity = tree.current_acidity
		b.sweetness = tree.current_sweetness
		b.flavor = tree.current_flavor
		b.bitterness = tree.current_bitterness
		b.moisture = tree.current_moisture
		b.defect_rate = tree.current_defect
		b.cherry_kg = 0 # Calculated at Harvest
	
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

func get_ready_batches_for_process(process_id: String, unlock_condition: String = "") -> Array[int]:
	var ready_years: Array[int] = []
	for y in batches.keys():
		var b = batches[y]
		if b.completed_processes.has("FP04") and not b.completed_processes.has(process_id):
			if unlock_condition == "" or b.completed_processes.has(unlock_condition):
				var already_placed = false
				for tile_dict in active_tiles:
					if tile_dict.data.process_id == process_id and tile_dict.has("target_batch_year") and tile_dict.target_batch_year == y:
						already_placed = true
						break
				if not already_placed:
					ready_years.append(y)
	return ready_years
	
func register_placed_tile(tile_node: Node3D, card_data: CardData, extra_data: Dictionary = {}) -> void:
	if card_data == null:
		return
		
	var duration = card_data.duration
	if extra_data.has("turn_duration"):
		duration = extra_data["turn_duration"]

	var tile_labels = _find_tile_labels(tile_node)
	if tile_labels:
		tile_labels.set_turn(duration)
		if current_location:
			tile_labels.set_lahan_name(current_location.location_name)
			
	var tile_dict = {
		"tile": tile_node,
		"data": card_data,
		"remaining_duration": duration,
		"tile_labels": tile_labels,
		"paid": false,
		"ready": false
	}
	tile_dict.merge(extra_data)
	
	if duration <= 0:
		if card_data.requires_interaction:
			tile_dict.ready = true
			if tile_labels:
				tile_labels.set_ready_state(true)
		else:
			# Apply effects immediately for normal cards
			var target_b = get_oldest_ready_batch(card_data.process_id)
			if target_b:
				target_b.apply_effects(tile_dict)
			stats_changed.emit()
			if tile_node and is_instance_valid(tile_node):
				PlacementManager.remove_tile_from_grid(tile_node)
			return # Do not append to active_tiles if instantly resolved
			
	active_tiles.append(tile_dict)


func unregister_placed_tile(tile_node: Node3D) -> void:
	for i in range(active_tiles.size() - 1, -1, -1):
		if active_tiles[i].tile == tile_node:
			active_tiles.remove_at(i)
			break



func _find_tile_labels(node: Node) -> Node3D:
	for child in node.get_children():
		if child.name == "tile_labels" or child.has_method("set_ready_state"):
			return child
		var found = _find_tile_labels(child)
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
			var final_cost = tile_dict.data.cost
			if tile_dict.has("override_cost"):
				final_cost = tile_dict["override_cost"]
			
			budget -= final_cost
			budget_changed.emit(budget)
			
		# Lock the tile if it's not locked yet
		if tile_dict.tile and is_instance_valid(tile_dict.tile) and not tile_dict.tile.has_meta("locked"):
			tile_dict.tile.set_meta("locked", true)
			
		if tile_dict.ready:
			continue # Already ready for interaction, don't tick duration
			
		tile_dict.remaining_duration -= 1
		
		if tile_dict.get("tile_labels") and is_instance_valid(tile_dict.tile_labels):
			tile_dict.tile_labels.set_turn(max(0, tile_dict.remaining_duration))
			
		if tile_dict.remaining_duration <= 0:
			if tile_dict.data.requires_interaction:
				tile_dict.ready = true
				if tile_dict.get("tile_labels") and is_instance_valid(tile_dict.tile_labels):
					tile_dict.tile_labels.set_ready_state(true)
			else:
				# Apply effects immediately for normal cards
				var target_b: CoffeeBatch = null
				if tile_dict.has("target_batch_year") and tile_dict.target_batch_year != -1:
					if batches.has(tile_dict.target_batch_year):
						target_b = batches[tile_dict.target_batch_year]
				if target_b == null:
					target_b = get_oldest_ready_batch(tile_dict.data.process_id)
				
				target_b.add_history(tile_dict.data.card_name)
				target_b.apply_effects(tile_dict)
				stats_changed.emit()
				if tile_dict.tile and is_instance_valid(tile_dict.tile):
					PlacementManager.remove_tile_from_grid(tile_dict.tile)
					
				# Remove from active ticking list
				active_tiles.remove_at(i)
				
	# Cleanup ghost batches (missed harvest)
	var dead_years = []
	for y in batches.keys():
		var b = batches[y]
		# Only delete if it's from a previous year and missed harvest
		if y < TimeManager.year and not b.completed_processes.has("FP04"):
			dead_years.append(y)
	for dy in dead_years:
		batches.erase(dy)
		print("Ghost batch removed for missed harvest in year ", dy)

	_check_stage_progression()
	turn_changed.emit(TimeManager.turn_in_year, TimeManager.season, TimeManager.year)
	
	# Try to fetch current year's batch to ensure it exists
	get_active_farm_batch()

func apply_missed_penalty(card_data: CardData) -> void:
	var target_b = get_oldest_ready_batch(card_data.process_id)
	if target_b:
		target_b.add_history("[Missed] " + card_data.card_name)
		target_b.accumulated_yield_modifier *= (1.0 + card_data.penalty_yield)
		target_b.aroma = clamp(target_b.aroma + card_data.penalty_aroma, 0.0, 100.0)
		target_b.acidity = clamp(target_b.acidity + card_data.penalty_acidity, 0.0, 100.0)
		target_b.body = clamp(target_b.body + card_data.penalty_body, 0.0, 100.0)
		target_b.sweetness = clamp(target_b.sweetness + card_data.penalty_sweetness, 0.0, 100.0)
		target_b.flavor = clamp(target_b.flavor + card_data.penalty_flavor, 0.0, 100.0)
		target_b.bitterness = clamp(target_b.bitterness + card_data.penalty_bitterness, 0.0, 100.0)
		target_b.moisture = clamp(target_b.moisture + card_data.penalty_moisture, 0.0, 100.0)
		target_b.defect_rate = clamp(target_b.defect_rate + card_data.penalty_defect, 0.0, 100.0)
		# yield penalty is now handled by accumulated_yield_modifier
		
	if current_location and current_location.current_tree:
		current_location.current_tree.health_pct = clamp(current_location.current_tree.health_pct + card_data.penalty_health, 0.0, 100.0)
	
	print("Penalti diberikan karena gagal menyelesaikan proses: ", card_data.card_name)
	stats_changed.emit()
	_check_stage_progression()

func is_tile_ready_for_interaction(tile_node: Node3D) -> bool:
	for dict in active_tiles:
		if dict.tile == tile_node and dict.ready:
			return true
	return false

func trigger_interaction(tile_node: Node3D) -> void:
	for dict in active_tiles:
		if dict.tile == tile_node and dict.ready:
			interaction_requested.emit(dict.data.card_name, dict)
			return

func resolve_interaction(tile_dict: Dictionary, process_next: bool) -> void:
	# Remove from active_tiles
	var index = active_tiles.find(tile_dict)
	if index != -1:
		active_tiles.remove_at(index)
		
	var target_b: CoffeeBatch = null
	if tile_dict.has("target_batch_year") and tile_dict.target_batch_year != -1:
		if batches.has(tile_dict.target_batch_year):
			target_b = batches[tile_dict.target_batch_year]
			
	if target_b == null:
		target_b = get_oldest_ready_batch(tile_dict.data.process_id)
		
	target_b.add_history(tile_dict.data.card_name)
	target_b.apply_effects(tile_dict)
	
	if tile_dict.data.process_id == "FP04":
		var raw_yield = current_location.current_tree.calculate_harvest_yield()
		var final_yield = raw_yield * target_b.accumulated_yield_modifier
		target_b.cherry_kg = int(clamp(final_yield, 0, 5000))
		
	if tile_dict.tile and is_instance_valid(tile_dict.tile):
		PlacementManager.remove_tile_from_grid(tile_dict.tile)
		
	if tile_dict.data.process_id == "DP01":
		batch_flags["after_roasting"] = true
		batch_flag_unlocked.emit("after_roasting")
	elif tile_dict.data.process_id == "TEST01":
		batch_flags["after_testing"] = true
		batch_flag_unlocked.emit("after_testing")
		
	if process_next:
		stats_changed.emit()
	else:
		# Temporarily disabled Sell logic until we reach the packing/selling phase
		# var income = (target_b.cherry_kg * 10) + (target_b.aroma * 5)
		# budget += income
		# budget_changed.emit(budget)
		# if batches.has(target_b.batch_year):
		# 	batches.erase(target_b.batch_year)
			
		stats_changed.emit()

func _check_stage_progression() -> void:
	# Define stage mapping according to GDD
	var turn_in_year = TimeManager.turn_in_year
	var next_stage = current_stage
	
	if turn_in_year == 1:
		next_stage = 0
		if not batches.has(TimeManager.year):
			_create_new_batch(TimeManager.year)
	
	if turn_in_year >= 1 and turn_in_year < 8:
		next_stage = 0 # Planting / Growing
	elif turn_in_year >= 8 and turn_in_year < 11:
		next_stage = 1 # Weeding & Pruning window
	elif turn_in_year >= 11 and turn_in_year < 13:
		next_stage = 3 # Suckering
	elif turn_in_year >= 13 and turn_in_year < 16:
		next_stage = 4 # Harvest
	elif turn_in_year >= 16:
		next_stage = 5 # Processing / Post-Harvest
	
	if next_stage != current_stage:
		current_stage = next_stage
		stage_changed.emit(current_stage)
		
func is_tile_locked(tile_node: Node3D) -> bool:
	return tile_node.has_meta("locked") and tile_node.get_meta("locked") == true

func is_process_active(process_id: String) -> bool:
	for dict in active_tiles:
		if dict.data and dict.data.process_id == process_id:
			return true
	return false
