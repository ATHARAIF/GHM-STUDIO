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

var is_placed: bool = false
var is_disabled: bool = false
var dragging: bool = false
var origin_parent: Control
var origin_index: int
var is_outside_hand: bool = false
var active_tween: Tween
#var drag_dummy: Control
var pending_rotation_steps: int = 0   # dipake pas resume drag dari pickup, biar rotasi kebawa

var target_batch_year: int = -1
var is_duplicate: bool = false

var card_color: Color = Color(0.85, 0.44, 0.25)
var tile_shape_icon: Texture2D
var requires_sunny_weather: bool = false

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _current_hover_state and card_data and card_data.process_id.begins_with("FP"):
			# Gunakan call_deferred agar aman jika PlacementManager sedang sibuk
			PlacementManager.call_deferred("toggle_farm_highlight", false)

func _ready() -> void:
	origin_parent = get_parent()
	mouse_filter = MOUSE_FILTER_STOP
	mouse_entered.connect(func(): _set_hover(true, false))
	mouse_exited.connect(func(): _set_hover(false, false))
	
	btn_info.mouse_entered.connect(func(): _set_hover(true, true))
	btn_info.mouse_exited.connect(func(): _set_hover(false, true))

	if card_data:
		_setup_ui()

var hover_tween: Tween
var _is_hovering_card: bool = false
var _is_hovering_btn: bool = false
var _hover_update_pending: bool = false
var _current_hover_state: bool = false

func _set_hover(state: bool, is_btn: bool) -> void:
	if is_btn:
		_is_hovering_btn = state
	else:
		_is_hovering_card = state
		
	if not _hover_update_pending:
		_hover_update_pending = true
		call_deferred("_update_hover_state")

func _update_hover_state() -> void:
	if not is_instance_valid(self) or is_queued_for_deletion(): return
	_hover_update_pending = false
	var should_hover = _is_hovering_card or _is_hovering_btn
	if should_hover != _current_hover_state:
		_current_hover_state = should_hover
		_apply_hover(should_hover)

func _apply_hover(is_hovered: bool) -> void:
	if is_hovered:
		if card_data and card_data.process_id.begins_with("FP"):
			PlacementManager.toggle_farm_highlight(true)
			
		if dragging or is_placed or is_outside_hand or is_disabled: return
		z_index = 10
		if hover_tween: hover_tween.kill()
		hover_tween = create_tween().set_parallel(true)
		hover_tween.tween_property($base, "scale", Vector2(0.55, 0.55), 0.1).set_trans(Tween.TRANS_SINE)
		hover_tween.tween_property($base, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	else:
		if card_data and card_data.process_id.begins_with("FP"):
			PlacementManager.toggle_farm_highlight(false)
			
		if dragging or is_placed or is_outside_hand or is_disabled: return
		z_index = 0
		if hover_tween: hover_tween.kill()
		hover_tween = create_tween().set_parallel(true)
		hover_tween.tween_property($base, "scale", Vector2(0.5, 0.5), 0.1).set_trans(Tween.TRANS_SINE)
		hover_tween.tween_property($base, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _setup_ui() -> void:
	if card_data:
		tile_scene = card_data.tile_scene
		tile_shape_icon = card_data.tile_shape_icon
		requires_sunny_weather = card_data.requires_sunny_weather
		card_color = card_data.card_color

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
			
	if pnl_color and pnl_color.has_theme_stylebox("panel"):
		var color_style = pnl_color.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if color_style: 
			color_style.bg_color = card_color
			pnl_color.add_theme_stylebox_override("panel", color_style)

func set_disabled(disabled: bool) -> void:
	is_disabled = disabled
	if is_disabled:
		modulate = Color(0.5, 0.5, 0.5, 0.8) # Gray and slightly transparent
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _gui_input(event: InputEvent) -> void:
	if is_disabled: return
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
	if origin_parent and origin_parent.has_method("set_card_played"):
		origin_parent.set_card_played(card_data, false)
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
		
		var new_idx = origin_index
		var siblings = origin_parent.get_children()
		for i in siblings.size():
			var sib = siblings[i]
			if sib == self or not sib.visible or ("is_placed" in sib and sib.is_placed):
				continue
			if mouse_pos.x > sib.global_position.x + (sib.size.x * 0.5):
				new_idx = i
		
		if new_idx != origin_index:
			origin_index = new_idx
			origin_parent.move_child(self, origin_index)

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
	z_index = 0
	if hover_tween: hover_tween.kill()
	$base.position.y = 0.0

	var mouse_pos := get_global_mouse_position()
	var placed := false

	if is_outside_hand:
		placed = PlacementManager.try_place(mouse_pos, tile_scene, card_data)

	if placed:
		# state [2] -> [3]: card gak di-free, cuma di-hide. Tetep hidup buat di-resume nanti.
		is_placed = true
		hide()
		_set_hover(false, false)
		_set_hover(false, true)
		if origin_parent and origin_parent.has_method("set_card_played"):
			origin_parent.set_card_played(card_data, true)
		top_level = false
		return

	# state [2] -> [1]: balik ke hand
	PlacementManager.end_drag()

	var start_pos := global_position   # posisi visual terakhir, masih bener karena top_level masih aktif
	origin_parent.move_child(self, origin_index)
	animate_return_from(start_pos)

func animate_return_from(from_pos: Vector2) -> void:
	dragging = false
	is_outside_hand = false
	is_placed = false
	if active_tween:
		active_tween.kill()

	# Langsung lepas dari layout top_level dan kembalikan ke parent
	top_level = false
	
	# Konversi posisi global (dari kursor) ke koordinat lokal parent agar lerp di parent mulus
	if origin_parent:
		position = origin_parent.get_global_transform().affine_inverse() * from_pos
	else:
		global_position = from_pos

	# Fade in animasi saja, perpindahan posisi akan otomatis diurus oleh _process di card_hand
	active_tween = create_tween()
	active_tween.tween_property(self, "modulate:a", 1.0, fade_duration).set_ease(Tween.EASE_OUT)
