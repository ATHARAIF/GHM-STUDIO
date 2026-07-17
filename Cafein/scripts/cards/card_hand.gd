extends HBoxContainer

func _ready() -> void:
	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.batch_flag_unlocked.connect(_on_batch_flag_unlocked)
	_update_cards_visibility()

func _on_turn_changed(turn: int, season: int) -> void:
	_update_cards_visibility()

func _on_batch_flag_unlocked(flag_name: String) -> void:
	_update_cards_visibility()

func _update_cards_visibility() -> void:
	for child in get_children():
		if child.has_method("get_card_data") or "card_data" in child:
			var cd = child.card_data
			if cd == null:
				continue
			
			var is_visible = false
			
			if cd.unlock_condition != "":
				if StageManager.batch_flags.has(cd.unlock_condition) and StageManager.batch_flags[cd.unlock_condition]:
					is_visible = true
			else:
				if StageManager.current_turn >= cd.turn_start:
					if cd.turn_over == 0 or StageManager.current_turn <= cd.turn_over:
						is_visible = true
						
			# If expired, maybe we should remove it? The GDD says "kartu hilang". 
			# For now, hiding it effectively removes it from hand.
			child.visible = is_visible
