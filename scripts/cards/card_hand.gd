extends HBoxContainer

var current_year: int = -1
var _is_first_update: bool = true

func _ready() -> void:
	current_year = TimeManager.year
	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.batch_flag_unlocked.connect(_on_batch_flag_unlocked)
	StageManager.stats_changed.connect(_on_stats_changed)
	_update_cards_visibility()

func _on_turn_changed(turn: int, season: int, year: int) -> void:
	if year > current_year:
		current_year = year
		# Reset all cards placed status on new year so they can be played again
		for child in get_children():
			if "is_placed" in child and ("card_data" in child or child.has_method("get_card_data")):
				var cd = child.get("card_data")
				if child.has_method("get_card_data"):
					cd = child.get_card_data()
					
				var is_still_on_ground = false
				if cd != null:
					for dict in StageManager.active_tiles:
						if dict.data == cd:
							is_still_on_ground = true
							break
				
				if not is_still_on_ground:
					child.is_placed = false
	_update_cards_visibility()

func _on_batch_flag_unlocked(flag_name: String) -> void:
	_update_cards_visibility()
	
func _on_stats_changed() -> void:
	_update_cards_visibility()

func _update_cards_visibility() -> void:
	var processed_card_data = []
	for child in get_children():
		if child.has_method("get_card_data") or "card_data" in child:
			var cd = child.card_data
			
			# Skip if it's a duplicate or we already processed this CardData type
			if cd == null or child.get("is_duplicate") or processed_card_data.has(cd):
				continue
				
			processed_card_data.append(cd)
			
			# We manage visibility based on CardData, not the specific placed state of the original.
			var was_visible = child.visible
			var is_visible = false
			
			match cd.availability:
				CardData.AvailabilityType.RECURRING_ANNUAL:
					var active_batch = StageManager.get_active_farm_batch()
					var curr = TimeManager.turn_in_year
					if cd.active_start_turn <= cd.active_end_turn:
						is_visible = (curr >= cd.active_start_turn and curr <= cd.active_end_turn)
					else:
						is_visible = (curr >= cd.active_start_turn or curr <= cd.active_end_turn)
					
					if active_batch and active_batch.completed_processes.has(cd.process_id):
						is_visible = false
						
					# Deteksi jika baru saja expired
					if not _is_first_update and was_visible and not is_visible:
						if active_batch and not active_batch.completed_processes.has(cd.process_id):
							# Pastikan juga tidak sedang aktif di field!
							if not StageManager.has_method("is_process_active") or not StageManager.is_process_active(cd.process_id):
								if has_node("/root/EventManager"):
									get_node("/root/EventManager").card_expired.emit(cd.process_id)
								child.visible = false
								StageManager.apply_missed_penalty(cd)
							
				CardData.AvailabilityType.EVENT_DRIVEN:
					is_visible = false
					var ready_years = StageManager.get_ready_batches_for_process(cd.process_id, cd.unlock_condition)
					
					# Cleanup dead duplicates
					for c in get_children():
						if c != child and c.has_method("get_card_data") and c.get("card_data") == cd and c.get("is_duplicate"):
							# Don't delete it if it's placed!
							if c.get("is_placed") == true: continue
							if not ready_years.has(c.get("target_batch_year")):
								c.queue_free()
								
					var available_idx = 0
					
					# If the original is placed, it stays hidden and cannot take a ready_year slot
					if child.get("is_placed") == true:
						is_visible = false
					elif ready_years.size() > 0:
						is_visible = true
						child.set("target_batch_year", ready_years[available_idx])
						if child.has_method("_setup_ui"):
							child._setup_ui()
						available_idx += 1
						
					# Create/Update duplicates for remaining ready_years
					while available_idx < ready_years.size():
						var year = ready_years[available_idx]
						var found = false
						for c in get_children():
							if c != child and c.has_method("get_card_data") and c.get("card_data") == cd and c.get("target_batch_year") == year:
								found = true
								break
						
						if not found:
							var dup = child.duplicate()
							dup.set("is_duplicate", true)
							dup.set("is_placed", false)
							dup.set("target_batch_year", year)
							add_child(dup)
							dup.visible = true
							dup.modulate.a = 1.0
							if dup.has_method("_setup_ui"):
								dup._setup_ui()
						available_idx += 1
						
				CardData.AvailabilityType.ONE_TIME_UNLOCK:
					is_visible = (TimeManager.year > cd.unlock_year) or (TimeManager.year == cd.unlock_year and TimeManager.turn_in_year >= cd.unlock_turn)
						
			if child.get("is_placed") == true:
				child.hide()
			elif is_visible:
				child.show()
				child.modulate.a = 1.0 # Ensure it's not transparent from previous dragging
				if child.has_method("_setup_ui"):
					child._setup_ui()
			else:
				child.hide()

	_is_first_update = false
