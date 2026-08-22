extends HBoxContainer

var current_year: int = -1

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
			if "is_placed" in child:
				child.is_placed = false
	_update_cards_visibility()

func _on_batch_flag_unlocked(flag_name: String) -> void:
	_update_cards_visibility()
	
func _on_stats_changed() -> void:
	_update_cards_visibility()

func _update_cards_visibility() -> void:
	for child in get_children():
		if child.has_method("get_card_data") or "card_data" in child:
			var cd = child.card_data
			if cd == null or (child.get("is_placed") != null and child.get("is_placed") == true):
				continue
			
			var was_visible = child.visible
			var is_visible = false
			
			match cd.availability:
				CardData.AvailabilityType.RECURRING_ANNUAL:
					var active_batch = StageManager.get_active_farm_batch()
					is_visible = (TimeManager.turn_in_year >= cd.active_start_turn and TimeManager.turn_in_year <= cd.active_end_turn)
					if active_batch and active_batch.completed_processes.has(cd.process_id):
						is_visible = false
						
					# Deteksi jika baru saja expired (lewat turn) dan belum dimainkan
					if TimeManager.turn_in_year == cd.active_end_turn + 1 and was_visible and not is_visible:
						if has_node("/root/EventManager"):
							get_node("/root/EventManager").card_expired.emit(cd.process_id)
						if active_batch and not active_batch.completed_processes.has(cd.process_id):
							child.visible = false # Cegah infinite recursion
							StageManager.apply_missed_penalty(cd)
							
				CardData.AvailabilityType.EVENT_DRIVEN:
					is_visible = false
					var active_batch = StageManager.get_active_farm_batch()
					if active_batch:
						if active_batch.completed_processes.has(cd.process_id):
							is_visible = false
						elif cd.unlock_condition != "" and active_batch.completed_processes.has(cd.unlock_condition):
							is_visible = true
						elif cd.unlock_condition == "":
							is_visible = true
						
				CardData.AvailabilityType.ONE_TIME_UNLOCK:
					is_visible = (TimeManager.year > cd.unlock_year) or (TimeManager.year == cd.unlock_year and TimeManager.turn_in_year >= cd.unlock_turn)
						
			if is_visible:
				child.modulate.a = 1.0
			child.visible = is_visible
