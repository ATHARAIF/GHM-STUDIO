extends HBoxContainer

## File Master cetakan kartu 2D. Masukkan "card_base.tscn" di sini.
@export var card_scene: PackedScene

## Folder tempat Anda menyimpan data kartu (.tres). 
## Game otomatis scan folder ini!
@export_dir var card_folders: Array[String] = []

# Internal database
var card_database: Array[CardData] = []
var current_year: int = -1
var played_cards_this_year: Array[CardData] = []
var expired_cards_this_year: Array[CardData] = []
var _is_first_update: bool = true

func _ready() -> void:
	current_year = TimeManager.year
	
	_auto_load_cards_from_folders()

	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.batch_flag_unlocked.connect(_on_batch_flag_unlocked)
	StageManager.stats_changed.connect(_on_stats_changed)
	_update_cards()

func _auto_load_cards_from_folders() -> void:
	card_database.clear()
	for folder_path in card_folders:
		var dir = DirAccess.open(folder_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					var actual_file = file_name
					if actual_file.ends_with(".remap"):
						actual_file = actual_file.replace(".remap", "")
						
					if actual_file.ends_with(".tres"):
						var full_path = folder_path + "/" + file_name
						var data = load(full_path) as CardData
						if data:
							card_database.append(data)
							
				file_name = dir.get_next()

func _on_turn_changed(turn: int, season: int, year: int) -> void:
	if year > current_year:
		current_year = year
		played_cards_this_year.clear()
		expired_cards_this_year.clear()
	_update_cards()

func _on_batch_flag_unlocked(flag_name: String) -> void:
	_update_cards()
	
func _on_stats_changed() -> void:
	_update_cards()

func _update_cards() -> void:
	if not card_scene:
		push_error("CardHand: card_scene belum diisi di Inspector!")
		return
		
	var active_batch = StageManager.get_active_farm_batch()
	var curr = TimeManager.turn_in_year
	
	for cd in card_database:
		if cd == null: continue
		
		# ========================================================
		# 1. EVALUATE AVAILABILITY & EXPIRATION
		# ========================================================
		var is_available = false
		var ready_years_event = []
		
		match cd.availability:
			CardData.AvailabilityType.RECURRING_ANNUAL:
				var is_active_time = false
				if cd.active_start_turn <= cd.active_end_turn:
					is_active_time = (curr >= cd.active_start_turn and curr <= cd.active_end_turn)
				else:
					is_active_time = (curr >= cd.active_start_turn or curr <= cd.active_end_turn)
					
				var is_completed = active_batch and active_batch.completed_processes.has(cd.process_id)
				var is_played_now = played_cards_this_year.has(cd)
				
				var req_met = true
				if active_batch:
					for req in cd.required_completed_processes:
						if not active_batch.completed_processes.has(req):
							req_met = false
							break
							
				var conflict_free = true
				if StageManager.has_method("is_process_active"):
					for conflict in cd.conflicting_active_processes:
						if StageManager.is_process_active(conflict):
							conflict_free = false
							break
				
				if is_active_time and not is_completed and not is_played_now and req_met and conflict_free:
					is_available = true
					
				# Expiration logic
				var is_past_expiration = false
				if cd.active_start_turn <= cd.active_end_turn:
					is_past_expiration = (curr > cd.active_end_turn)
				else:
					is_past_expiration = (curr > cd.active_end_turn and curr < cd.active_start_turn)
					
				if not _is_first_update and is_past_expiration and not is_completed and not is_played_now:
					if not expired_cards_this_year.has(cd):
						if not StageManager.has_method("is_process_active") or not StageManager.is_process_active(cd.process_id):
							if has_node("/root/EventManager"):
								get_node("/root/EventManager").card_expired.emit(cd.process_id)
							expired_cards_this_year.append(cd)
							StageManager.apply_missed_penalty(cd)
							
			CardData.AvailabilityType.EVENT_DRIVEN:
				ready_years_event = StageManager.get_ready_batches_for_process(cd.process_id, cd.unlock_condition)
				if ready_years_event.size() > 0:
					is_available = true
					
			CardData.AvailabilityType.ONE_TIME_UNLOCK:
				is_available = (TimeManager.year > cd.unlock_year) or (TimeManager.year == cd.unlock_year and TimeManager.turn_in_year >= cd.unlock_turn)

		# ========================================================
		# 2. SPAWN OR CLEANUP
		# ========================================================
		if cd.availability == CardData.AvailabilityType.EVENT_DRIVEN:
			# Cleanup obsolete event cards
			for c in get_children():
				if c.get("card_data") == cd and not c.get("is_placed"):
					if not ready_years_event.has(c.get("target_batch_year")):
						c.queue_free()
			# Spawn missing ones
			for year in ready_years_event:
				if not _has_card_instance(cd, year):
					_spawn_card(cd, year)
		else:
			var existing = _get_card_instance(cd)
			if is_available:
				if not existing:
					_spawn_card(cd)
			else:
				if existing and not existing.get("is_placed"):
					existing.queue_free()

	_is_first_update = false

func _has_card_instance(cd: CardData, target_year: int = -1) -> bool:
	for c in get_children():
		if c.get("card_data") == cd and not c.get("is_placed"):
			if target_year == -1 or c.get("target_batch_year") == target_year:
				return true
	return false

func _get_card_instance(cd: CardData) -> Node:
	for c in get_children():
		if c.get("card_data") == cd and not c.get("is_placed"):
			return c
	return null


@export_group("Dynamic Layout")
@export var max_hand_width: float = 1000.0
@export var default_separation: int = 15
@export var card_width: float = 132.0
@export var max_overlap: int = 80

func _process(delta: float) -> void:
	_update_dynamic_overlap()

func _update_dynamic_overlap() -> void:
	var visible_cards = 0
	for c in get_children():
		if c.visible and not (c.get("is_placed") == true) and not (c.get("is_outside_hand") == true):
			visible_cards += 1
			
	if visible_cards <= 1:
		add_theme_constant_override("separation", default_separation)
		return
		
	var normal_width = (visible_cards * card_width) + ((visible_cards - 1) * default_separation)
	
	if normal_width > max_hand_width:
		var overlap_space = max_hand_width - (visible_cards * card_width)
		var new_separation = overlap_space / (visible_cards - 1)
		add_theme_constant_override("separation", int(new_separation))
	else:
		add_theme_constant_override("separation", default_separation)

func _spawn_card(cd: CardData, target_year: int = -1) -> void:
	var c = card_scene.instantiate()
	c.set("card_data", cd)
	c.set("is_placed", false)
	c.set("target_batch_year", target_year)
	add_child(c)

func set_card_played(cd: CardData, played: bool) -> void:
	if played:
		if not played_cards_this_year.has(cd):
			played_cards_this_year.append(cd)
	else:
		if played_cards_this_year.has(cd):
			played_cards_this_year.erase(cd)
