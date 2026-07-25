extends HBoxContainer

func _ready() -> void:
	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.batch_flag_unlocked.connect(_on_batch_flag_unlocked)
	StageManager.stats_changed.connect(_on_stats_changed)
	_update_cards_visibility()

func _on_turn_changed(turn: int, season: int, _year: int) -> void:
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
			
			var is_visible = false
			
			match cd.availability:
				CardData.AvailabilityType.RECURRING_ANNUAL:
					is_visible = (TimeManager.turn_in_year >= cd.active_start_turn and TimeManager.turn_in_year <= cd.active_end_turn)
					# Sembunyikan jika batch tahun ini sudah menyelesaikan stage tersebut
					var active_batch = StageManager.get_active_farm_batch()
					if active_batch and active_batch.completed_stages.has(cd.stage_id):
						is_visible = false
						
				CardData.AvailabilityType.ONE_TIME_UNLOCK:
					is_visible = (TimeManager.year > cd.unlock_year) or (TimeManager.year == cd.unlock_year and TimeManager.turn_in_year >= cd.unlock_turn)
				CardData.AvailabilityType.EVENT_DRIVEN:
					is_visible = (cd.unlock_condition != "" and StageManager.batch_flags.has(cd.unlock_condition) and StageManager.batch_flags[cd.unlock_condition])
						
			# If expired, maybe we should remove it? The GDD says "kartu hilang". 
			# For now, hiding it effectively removes it from hand.
			if is_visible:
				child.modulate.a = 1.0
			child.visible = is_visible
