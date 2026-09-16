extends Control

@export var phase_name: String = "Planting"
@export var phase_icon: Texture2D

# Status bisa "IDLE", "IN_PROGRESS", "COMPLETED", "SKIPPED"
@export_enum("IDLE", "IN_PROGRESS", "COMPLETED", "SKIPPED") var status: String = "IDLE"
@export var progress: float = 0.0

@onready var hover_label = $TooltipText
@onready var card_panel = $CardPanel
@onready var icon = $CardPanel/VBox/Icon
#@onready var progress_bar = $CardPanel/BorderProgress

var _tween: Tween

func _ready() -> void:
	# Setup initial data
	hover_label.text = phase_name
	if phase_icon:
		icon.texture = phase_icon
		
	_update_visuals()
	
	# Connect signals for hover effects
	card_panel.mouse_entered.connect(_on_hover_enter)
	card_panel.mouse_exited.connect(_on_hover_exit)

func set_state(new_status: String, new_progress: float = 0.0) -> void:
	status = new_status
	progress = new_progress
	_update_visuals()

func _update_visuals() -> void:
	# Kita buat duplikat dari stylebox agar perubahan warna di satu kartu
	# tidak ikut merubah warna kartu yang lain.
	var style = card_panel.get_theme_stylebox("panel").duplicate()
	card_panel.add_theme_stylebox_override("panel", style)
	
	# Set ketebalan border (misal 3 pixel di semua sisi)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	
	match status:
		"IDLE":
			card_panel.modulate = Color(0.706, 0.714, 0.706, 1.0) # Redup
			style.border_color = Color(0.706, 0.714, 0.706, 1.0) # Redup
		"SKIPPED":
			card_panel.modulate = Color.WHITE # Kembalikan ke warna asli agar ikon tidak butek
			style.bg_color = Color(0.3, 0.1, 0.1, 1.0) # Ganti latar belakang kotak jadi merah gelap
			style.border_color = Color(0.8, 0.2, 0.2, 1.0) # Border merah tajam
		"IN_PROGRESS":
			card_panel.modulate = Color(1.0, 1.0, 1.0, 1.0) # Terang
			style.border_color = Color(1.0, 0.8, 0.2) # Kuning/Oranye cerah
		"COMPLETED":
			card_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
			style.border_color = Color(0.2, 0.8, 0.4) # Hijau

func _on_hover_enter() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Geser kartu ke atas sedikit
	_tween.tween_property(card_panel, "position:y", -13.0, 0.25)
	# Munculkan teks
	_tween.tween_property(hover_label, "modulate:a", 1.0, 0.2)

func _on_hover_exit() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Kembalikan kartu ke posisi awal
	_tween.tween_property(card_panel, "position:y", 0.0, 0.25)
	# Sembunyikan teks
	_tween.tween_property(hover_label, "modulate:a", 0.0, 0.2)
