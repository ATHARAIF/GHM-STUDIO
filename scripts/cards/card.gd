extends Control
class_name Card

## Scene 3D (Tile) yang akan di-spawn/dimunculkan saat kartu ini dijatuhkan ke lahan.
@export var tile_scene: PackedScene
## Data Resource (.tres) yang menyimpan informasi nama, biaya, efek, dan aturan kartu ini.
@export var card_data: CardData
## Durasi animasi memudar (fade out) saat kartu dimainkan (detik).
@export var fade_duration: float = 0.15
## Durasi animasi kartu kembali ke tangan jika batal ditaruh (detik).
@export var return_duration: float = 0.25

# ===== STATE =====
# [1] STANDBY  - card diem di hand (dragging=false, visible=true)
# [2] DRAGGING - lagi ditarik user, entah dari hand atau dari hasil pickup ground (dragging=true)
# [3] PLACED   - udah jadi tile di ground, card-nya di-hide tapi TETEP HIDUP (bukan di-free)

var dragging: bool = false
var is_placed: bool = false
var origin_parent: Control
var origin_index: int
var is_outside_hand: bool = false
var active_tween: Tween
var pending_rotation_steps: int = 0   # dipake pas resume drag dari pickup, biar rotasi kebawa

var target_batch_year: int = -1
var is_duplicate: bool = false

@export_group("Card UI Design")
@export var card_color: Color = Color(0.85, 0.44, 0.25)
@export var tile_shape_icon: Texture2D
@export var requires_sunny_weather: bool = false

@onready var lbl_process = $base/color/process_name/label
@onready var lbl_target = $base/lahan
@onready var lbl_turn = $base/color/specs/container/turn/label
@onready var lbl_cost = $base/color/cost/label

@onready var tex_tile_type = $base/color/specs/container/tile_type
@onready var tex_weather = $base/color/specs/container/weather
@onready var tex_illustration = get_node_or_null("base/illustration")
@onready var btn_info = $base/color/process_name/info_button

@onready var pnl_base = $base
@onready var pnl_specs = $base/color/specs
@onready var pnl_color = $base/color

func _ready() -> void:
	origin_parent = get_parent()
	mouse_filter = MOUSE_FILTER_STOP
	
	if card_data:
		_setup_ui()

func _setup_ui() -> void:
	if lbl_process:
		lbl_process.text = card_data.card_name.to_upper()
	if lbl_turn:
		lbl_turn.text = str(card_data.duration)
	if lbl_cost:
		lbl_cost.text = "%d" % card_data.cost
		
	if tex_tile_type and tile_shape_icon:
		tex_tile_type.texture = tile_shape_icon
		
	if tex_weather:
		if requires_sunny_weather:
			tex_weather.modulate.a = 1.0
		else:
			tex_weather.modulate.a = 0.0
		
	var loc = StageManager.current_location
	var var_name = "Kopi"
	if loc and loc.variety_data:
		var_name = loc.variety_data.variety_name
		
	if lbl_target:
		if card_data.process_id.begins_with("F"):
			if loc:
				lbl_target.text = loc.location_name.to_upper()
			else:
				lbl_target.text = "LAHAN"
		else:
			var display_year = TimeManager.year
			if target_batch_year != -1:
				display_year = target_batch_year
			lbl_target.text = ("%s %d" % [var_name, display_year]).to_upper()
			
	if pnl_base and pnl_base.has_theme_stylebox("panel"):
		var base_style = pnl_base.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if base_style: 
			base_style.bg_color = card_color
			pnl_base.add_theme_stylebox_override("panel", base_style)
		
	if pnl_specs and pnl_specs.has_theme_stylebox("panel"):
		var specs_style = pnl_specs.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if specs_style:
			specs_style.bg_color = card_color
			pnl_specs.add_theme_stylebox_override("panel", specs_style)



func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if card_data and StageManager.budget < card_data.cost:
			return # Cannot afford
		_begin_drag(global_position)
		get_viewport().set_input_as_handled()

# dipanggil PlacementManager pas user klik tile yang UDAH ditaro di ground (state [3] -> [2]).
# card ini instance YANG SAMA dari waktu dia ditaro dulu, gak dibikin ulang -- jadi semua
# data (label, ukuran, dll) otomatis konsisten, gak perlu di-restore manual satu-satu.
func resume_drag_at(mouse_pos: Vector2, initial_rotation_steps: int = 0) -> void:
	pending_rotation_steps = initial_rotation_steps
	is_placed = false
	show()
	modulate.a = 1.0
	_begin_drag(mouse_pos - size / 2.0)

# titik masuk tunggal buat mulai state [2], dipanggil baik dari klik card di hand
# maupun dari resume_drag_at() pas pickup dari ground.
func _begin_drag(start_screen_pos: Vector2) -> void:
	if active_tween:
		active_tween.kill()

	origin_parent = get_parent()
	origin_index = get_index()
	top_level = true
	global_position = start_screen_pos
	is_outside_hand = false
	dragging = true

func _process(_delta: float) -> void:
	if not dragging:
		return

	var mouse_pos := get_global_mouse_position()
	global_position = mouse_pos - size / 2.0

	var hand_rect := origin_parent.get_global_rect()
	var now_outside := not hand_rect.has_point(mouse_pos)

	if now_outside != is_outside_hand:
		is_outside_hand = now_outside
		_update_visual_state()

	if is_outside_hand:
		PlacementManager.update_ghost(mouse_pos)
		if Input.is_action_just_pressed("rotate"):
			PlacementManager.rotate_ghost()
	else:
		PlacementManager.cancel_ghost()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_end_drag()

# titik masuk tunggal buat transisi [1]<->[2]: fade card + kasih tau PlacementManager.
# dipanggil baik pas keluar-masuk hand dari drag biasa, maupun pas resume dari pickup ground.
func _update_visual_state() -> void:
	if active_tween:
		active_tween.kill()

	active_tween = create_tween()
	if is_outside_hand:
		active_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
		PlacementManager.begin_drag(tile_scene, self, pending_rotation_steps)
		pending_rotation_steps = 0
	else:
		active_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
		PlacementManager.end_drag()

func _end_drag() -> void:
	dragging = false

	var mouse_pos := get_global_mouse_position()
	var placed := false

	if is_outside_hand:
		placed = PlacementManager.try_place(mouse_pos, tile_scene, card_data)

	if placed:
		# state [2] -> [3]: card gak di-free, cuma di-hide. Tetep hidup buat di-resume nanti.
		is_placed = true
		hide()
		top_level = false
		return

	# state [2] -> [1]: balik ke hand
	PlacementManager.end_drag()

	var start_pos := global_position   # posisi visual terakhir, masih bener karena top_level masih aktif
	origin_parent.move_child(self, origin_index)
	animate_return_from(start_pos)

func animate_return_from(from_pos: Vector2) -> void:
	if active_tween:
		active_tween.kill()

	# matiin top_level dulu biar container ngitung posisi global yang BENER
	top_level = false
	origin_parent.queue_sort()

	# nunggu 2 frame: frame pertama buat container ngitung ulang total minimum_size
	# (penting kalo card ini baru masuk lagi ke container di frame yang sama),
	# frame kedua buat mastiin posisi child udah beneran final/stabil.
	await get_tree().process_frame
	await get_tree().process_frame

	var target_pos := global_position   # sekarang valid, karena dihitung pas top_level udah false

	top_level = true            # nyalain lagi buat proses tween manual
	global_position = from_pos
	modulate.a = 1.0             # langsung keliatan lagi, gak usah di-fade

	active_tween = create_tween()
	active_tween.tween_property(self, "global_position", target_pos, return_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await active_tween.finished
	top_level = false
	global_position = target_pos   # re-sync posisi lokal setelah top_level off, biar gak "loncat"
