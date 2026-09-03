extends Control

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

enum SpawnAnimation {
	POP_IN, ## Kartu membesar dari tengah dengan efek membal
	SLIDE_UP, ## Kartu meluncur dari bawah sambil memudar masuk
	SLIDE_DOWN, ## Kartu meluncur dari atas sambil memudar masuk
	FADE_IN, ## Kartu perlahan muncul tanpa perpindahan
	DEAL_FROM_LEFT, ## Kartu terbang dari luar layar kiri
	DEAL_FROM_RIGHT, ## Kartu terbang dari luar layar kanan
	SPIN_IN ## Kartu berputar-putar liar sebelum berhenti di tangkapan
}

enum DiscardAnimation {
	SHRINK_OUT, ## Kartu mengecil lalu hilang
	SLIDE_DOWN, ## Kartu merosot ke bawah lalu memudar
	SLIDE_UP, ## Kartu melayang ke atas lalu memudar
	FADE_OUT, ## Kartu memudar secara halus di tempat
	BURN_UP, ## Kartu terbang ke atas sangat cepat dengan glow merah (kalau bisa)
	FLY_LEFT, ## Terlempar keluar layar ke kiri
	FLY_RIGHT, ## Terlempar keluar layar ke kanan
	SPIN_OUT ## Kartu berputar kencang lalu menghilang
}

@export_group("Animation Styles")
## Gaya animasi saat kartu muncul
@export var spawn_style: SpawnAnimation = SpawnAnimation.POP_IN
## Gaya animasi saat kartu hangus/dibuang
@export var discard_style: DiscardAnimation = DiscardAnimation.SHRINK_OUT
## Durasi animasi kartu muncul (detik)
@export var spawn_duration: float = 0.4
## Durasi animasi kartu hangus/dibuang (detik)
@export var discard_duration: float = 0.3

@export_group("Dynamic Layout")
## Batas maksimal ruang (lebar pixel) untuk membentangkan kartu. Jika jumlah kartu melampaui ini, kartu akan bertumpuk (overlap) agar tidak keluar layar.
@export var max_hand_width: float = 1000.0
## Jarak rongga kosong standar antar kartu saat jumlah kartu masih sedikit (bisa diatur ke angka minus jika ingin selalu berdempetan).
@export var default_separation: int = 15
## Patokan lebar asli dari desain UI kartu Anda. Hanya ubah jika Anda mendesain ulang lebar kartu di card_base.tscn.
@export var card_width: float = 132.0
## Seberapa dalam kartu di pinggir (kiri/kanan) merosot ke bawah untuk membentuk formasi kipas. Set ke 0.0 jika ingin lurus rata.
@export var fan_curve_intensity: float = 40.0
## Seberapa miring kartu di pinggir berotasi (derajat). Set ke 0.0 jika ingin kartu selalu berdiri tegak.
@export var fan_rotation_intensity: float = 15.0

func _ready() -> void:
	current_year = TimeManager.year
	
	_auto_load_cards_from_folders()

	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.batch_flag_unlocked.connect(_on_batch_flag_unlocked)
	StageManager.stats_changed.connect(_on_stats_changed)
	
	# Panggil dengan defer agar semua node (termasuk main_farm) selesai _ready 
	# dan restore_room_state selesai dijalankan sebelum mengecek kartu
	call_deferred("_update_cards")

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
	
	var spawn_count_this_frame = 0
	var base_delay = 0.6 if _is_first_update else 0.0 # Tunggu transisi layar selesai saat awal mula
	
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
				if StageManager.has_method("is_process_active") and StageManager.is_process_active(cd.process_id):
					is_played_now = true
				
				var req_met = true
				if active_batch:
					for req in cd.required_completed_processes:
						if not active_batch.completed_processes.has(req):
							req_met = false
							break
					for inv in cd.invalid_if_processes_completed:
						if active_batch.completed_processes.has(inv):
							req_met = false
							break
							
				var conflict_free = true
				if StageManager.has_method("is_process_active"):
					for conflict in cd.conflicting_active_processes:
						if StageManager.is_process_active(conflict):
							conflict_free = false
							break
				
				if is_active_time and not is_completed and not is_played_now and req_met:
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
						_discard_card(c)
			# Spawn missing ones
			for year in ready_years_event:
				if not _has_card_instance(cd, year):
					_spawn_card(cd, year, base_delay + (spawn_count_this_frame * 0.15))
					spawn_count_this_frame += 1
		else:
			var existing = _get_card_instance(cd)
			if is_available:
				if not existing:
					_spawn_card(cd, -1, base_delay + (spawn_count_this_frame * 0.15))
					spawn_count_this_frame += 1
			else:
				if existing and not existing.get("is_placed"):
					_discard_card(existing)
					
	# Urutkan kartu yang ada di tangan sesuai dengan urutan di card_database
	var local_index = 0
	for cd in card_database:
		for c in get_children():
			if c.get("card_data") == cd and not c.get("is_placed") and not c.is_queued_for_deletion():
				# Cek apakah kartu sedang konflik (disable status)
				var conflict_free = true
				if StageManager.has_method("is_process_active"):
					for conflict in cd.conflicting_active_processes:
						if StageManager.is_process_active(conflict):
							conflict_free = false
							break
				if c.has_method("set_disabled"):
					c.set_disabled(not conflict_free)
					
				move_child(c, local_index)
				local_index += 1

	_is_first_update = false

func _has_card_instance(cd: CardData, target_year: int = -1) -> bool:
	for c in get_children():
		if c.get("card_data") == cd and not c.get("is_placed") and not c.is_queued_for_deletion():
			if target_year == -1 or c.get("target_batch_year") == target_year:
				return true
	return false

func _get_card_instance(cd: CardData) -> Node:
	for c in get_children():
		if c.get("card_data") == cd and not c.get("is_placed") and not c.is_queued_for_deletion():
			return c
	return null

func _process(delta: float) -> void:
	_update_dynamic_overlap(delta)

func _update_dynamic_overlap(delta: float) -> void:
	var visible_cards = []
	for c in get_children():
		if c.visible and not c.is_queued_for_deletion() and not c.get("is_placed") and not c.get("dragging") and not c.get("is_outside_hand"):
			visible_cards.append(c)
			
	var count = visible_cards.size()
	if count == 0:
		return
		
	var total_card_width = (count * card_width) + ((count - 1) * default_separation)
	var step_x = card_width + default_separation
	
	if total_card_width > max_hand_width:
		step_x = (max_hand_width - card_width) / max(1, count - 1)
		
	var actual_total_width = card_width + (count - 1) * step_x
	var start_x = (size.x - actual_total_width) / 2.0
	
	for i in range(count):
		var c = visible_cards[i]
		
		# Hitung posisi target X
		var target_x = start_x + (i * step_x)
		var target_y = 0.0
		var target_rot = 0.0
		
		# Efek lengkungan kipas berdasar posisi asli kartu terhadap tengah layar
		# Semakin jauh dari tengah layar, semakin melengkung (sehingga jika hanya 2 kartu di tengah, lengkungannya sangat kecil)
		var hand_center_x = size.x / 2.0
		var card_center_x = target_x + (card_width / 2.0)
		var distance_from_center = card_center_x - hand_center_x
		
		# Normalisasi jarak (-0.5 sampai 0.5) berdasarkan max_hand_width
		var centered = (distance_from_center / (max_hand_width / 2.0)) * 0.5
		
		# Semakin ke ujung layar, semakin turun ke bawah (parabola)
		target_y = abs(centered) * abs(centered) * fan_curve_intensity * 4.0 # x4 karena max abs(centered) sekarang 0.5
		# Semakin ke ujung layar, rotasinya semakin miring
		target_rot = (centered * fan_rotation_intensity * 2.0) # x2 karena max centered 0.5
			
		target_rot += c.get_meta("anim_rot_offset", 0.0)
			
		var target_pos = Vector2(target_x, target_y) + c.get_meta("anim_offset", Vector2.ZERO)
		
		# Lerp mulus posisi dan rotasi
		c.position = c.position.lerp(target_pos, 15.0 * delta)
		c.rotation_degrees = lerp(c.rotation_degrees, target_rot, 15.0 * delta)

func _spawn_card(cd: CardData, target_year: int = -1, delay: float = 0.0) -> void:
	var c = card_scene.instantiate()
	c.set("card_data", cd)
	c.set("is_placed", false)
	c.set("target_batch_year", target_year)
	add_child(c)
	
	# Set pivot di TENGAH BAWAH (Bottom Center) agar saat memekar, ujung bawahnya tetap rapat layaknya memegang kartu asli
	c.pivot_offset = Vector2(card_width / 2.0, c.custom_minimum_size.y)
	
	# Posisikan c di tengah terlebih dahulu agar saat muncul (Pop In) posisinya terlihat natural
	c.position = Vector2(size.x / 2.0 - card_width / 2.0, 0.0)
		
	var tween = create_tween()
	
	# Set state awal sebelum jeda agar kartu tidak bocor (terlihat) saat menunggu
	match spawn_style:
		SpawnAnimation.POP_IN, SpawnAnimation.SPIN_IN:
			c.scale = Vector2.ZERO
		_:
			c.modulate.a = 0.0
			
	# Tambahkan jeda waktu sebelum animasi jalan
	if delay > 0.0:
		tween.tween_interval(delay)
		
	match spawn_style:
		SpawnAnimation.POP_IN:
			tween.tween_property(c, "scale", Vector2(1, 1), spawn_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
		SpawnAnimation.SLIDE_UP:
			c.set_meta("anim_offset", Vector2(0, 150))
			tween.set_parallel(true)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2(0, 150), Vector2.ZERO, spawn_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(c, "modulate:a", 1.0, spawn_duration)
			tween.set_parallel(false)
			
		SpawnAnimation.SLIDE_DOWN:
			c.set_meta("anim_offset", Vector2(0, -150))
			tween.set_parallel(true)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2(0, -150), Vector2.ZERO, spawn_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(c, "modulate:a", 1.0, spawn_duration)
			tween.set_parallel(false)
			
		SpawnAnimation.FADE_IN:
			tween.tween_property(c, "modulate:a", 1.0, spawn_duration)
			
		SpawnAnimation.DEAL_FROM_LEFT:
			c.set_meta("anim_offset", Vector2(-800, 0))
			tween.set_parallel(true)
			tween.tween_property(c, "modulate:a", 1.0, 0.1) # Muncul cepat saat mulai terbang
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2(-800, 0), Vector2.ZERO, spawn_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.set_parallel(false)
			
		SpawnAnimation.DEAL_FROM_RIGHT:
			c.set_meta("anim_offset", Vector2(800, 0))
			tween.set_parallel(true)
			tween.tween_property(c, "modulate:a", 1.0, 0.1)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2(800, 0), Vector2.ZERO, spawn_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.set_parallel(false)
			
		SpawnAnimation.SPIN_IN:
			c.set_meta("anim_rot_offset", -720.0) # Putar 2x (720 derajat)
			tween.set_parallel(true)
			tween.tween_property(c, "scale", Vector2(1, 1), spawn_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_method(func(val): c.set_meta("anim_rot_offset", val), -720.0, 0.0, spawn_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.set_parallel(false)

func _discard_card(c: Node) -> void:
	var tween = create_tween()
	match discard_style:
		DiscardAnimation.SHRINK_OUT:
			tween.tween_property(c, "scale", Vector2.ZERO, discard_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			
		DiscardAnimation.SLIDE_DOWN:
			tween.set_parallel(true)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2.ZERO, Vector2(0, 150), discard_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(c, "modulate:a", 0.0, discard_duration)
			
		DiscardAnimation.SLIDE_UP:
			tween.set_parallel(true)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2.ZERO, Vector2(0, -150), discard_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(c, "modulate:a", 0.0, discard_duration)
			
		DiscardAnimation.FADE_OUT:
			tween.tween_property(c, "modulate:a", 0.0, discard_duration)
			
		DiscardAnimation.BURN_UP:
			tween.set_parallel(true)
			tween.tween_property(c, "modulate", Color(1, 0.2, 0.2, 0.0), discard_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2.ZERO, Vector2(0, -200), discard_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			
		DiscardAnimation.FLY_LEFT:
			tween.set_parallel(true)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2.ZERO, Vector2(-800, 0), discard_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_method(func(val): c.set_meta("anim_rot_offset", val), 0.0, -45.0, discard_duration)
			
		DiscardAnimation.FLY_RIGHT:
			tween.set_parallel(true)
			tween.tween_method(func(val): c.set_meta("anim_offset", val), Vector2.ZERO, Vector2(800, 0), discard_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_method(func(val): c.set_meta("anim_rot_offset", val), 0.0, 45.0, discard_duration)
			
		DiscardAnimation.SPIN_OUT:
			tween.set_parallel(true)
			tween.tween_property(c, "scale", Vector2.ZERO, discard_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_method(func(val): c.set_meta("anim_rot_offset", val), 0.0, 720.0, discard_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
			
	tween.chain().tween_callback(c.queue_free)

func set_card_played(cd: CardData, played: bool) -> void:
	if played:
		if not played_cards_this_year.has(cd):
			played_cards_this_year.append(cd)
	else:
		if played_cards_this_year.has(cd):
			played_cards_this_year.erase(cd)
