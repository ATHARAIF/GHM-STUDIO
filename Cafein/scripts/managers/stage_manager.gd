extends Node

signal turn_changed(turn: int, season: int)
signal stage_changed(stage: int)
signal budget_changed(budget: int)
signal stats_changed()
signal interaction_requested(interaction_type: String, tile_data: Dictionary)

enum Season { SPRING, SUMMER, FALL, WINTER }

var current_stage: int = 0
var current_turn: int = 1
var current_season: int = Season.SPRING
var budget: int = 50000
var current_location: FarmLocation
var coffee_batch: CoffeeBatch

var active_tiles: Array[Dictionary] = []
var batch_flags: Dictionary = {}
signal batch_flag_unlocked(flag_name: String) # { "tile": Node3D, "data": CardData, "remaining_duration": int, "label": Label3D }


func _ready() -> void:
	current_location = FarmLocation.new()
	
	coffee_batch = CoffeeBatch.new()
	# Inisialisasi stat awal digabung dengan bonus dari lahan / varietas
	coffee_batch.aroma = current_location.base_aroma
	coffee_batch.body = current_location.base_body
	# Default acidity di GDD adalah 50, lalu dimodifikasi oleh varietas (-5)
	coffee_batch.acidity = clamp(50 + current_location.base_acidity, 0, 100)
	
func register_placed_tile(tile_node: Node3D, card_data: CardData) -> void:
	if card_data == null:
		return
		
	var label = _find_turn_label(tile_node)
	if label:
		label.text = str(card_data.duration)
		
	var name_label = _find_bean_name_label(tile_node)
	if name_label and current_location:
		name_label.text = current_location.location_name
		
	active_tiles.append({
		"tile": tile_node,
		"data": card_data,
		"remaining_duration": card_data.duration,
		"label": label,
		"paid": false,
		"ready": false
	})


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

func _find_bean_name_label(node: Node) -> Label3D:
	for child in node.get_children():
		if child is Label3D and child.name == "bean_name":
			return child
		var found = _find_bean_name_label(child)
		if found: return found
	return null

func advance_turn() -> void:
	current_turn += 1
	if current_turn > 20:
		pass # Demoo ends here conceptually
		
	@warning_ignore("integer_division")
	var season_idx = int((current_turn - 1) / 5) % 4
	current_season = season_idx
	
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
				coffee_batch.apply_effects(tile_dict.data)
				stats_changed.emit()
				if tile_dict.tile and is_instance_valid(tile_dict.tile):
					PlacementManager.remove_tile_from_grid(tile_dict.tile)
					
				# Remove from active ticking list
				active_tiles.remove_at(i)
				
	turn_changed.emit(current_turn, current_season)
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
		
	coffee_batch.apply_effects(tile_dict.data)
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
		var income = (coffee_batch.yield_kg * 10) + (coffee_batch.aroma * 5)
		budget += income
		budget_changed.emit(budget)

		
		# Reset batch as it is sold
		var old_completed = coffee_batch.completed_stages.duplicate()
		coffee_batch = CoffeeBatch.new()
		coffee_batch.completed_stages = old_completed
		if current_location:
			coffee_batch.aroma = current_location.base_aroma
			coffee_batch.body = current_location.base_body
			coffee_batch.acidity = clamp(50 + current_location.base_acidity, 0, 100)
			
		stats_changed.emit()

func _check_stage_progression() -> void:
	# Define stage mapping according to GDD
	var turn_in_year = ((current_turn - 1) % 20) + 1
	var next_stage = current_stage
	
	if turn_in_year == 1:
		next_stage = 0
		if coffee_batch:
			coffee_batch.completed_stages.clear()
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
