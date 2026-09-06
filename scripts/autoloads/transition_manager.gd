extends CanvasLayer

signal transition_halfway
signal transition_finished

enum TransitionPreset {
	# Basic Wipes
	SIMPLE_FADE,
	LEFT_TO_RIGHT,
	CENTER_WIPE,
	BLINDER_WIPE,
	GRID_REVEAL,
	
	# Shapes
	IRIS_CIRCLE,
	DIAMOND_SHAPE,
	SCRATCH_LINES_REVEAL,
	OVERLAPPING_DIAMONDS,
	SPIKE_TRAP,
	
	# Clocks
	CORNER_CLOCK,
	CENTER_CLOCK,
	FAN_TRANSITION,
	SEAMLESS_FLOWER,
	HOURGLASS_WIPE,
	DOUBLE_DIAMOND,
	
	CUSTOM
}

@export var current_preset: TransitionPreset = TransitionPreset.LEFT_TO_RIGHT

@onready var color_rect: ColorRect = $ColorRect
@onready var shader_mat: ShaderMaterial = color_rect.material as ShaderMaterial

# Waktu transisi (dalam detik), sekarang bisa diatur dari Inspector!
@export var transition_duration: float = 0.5 
# Batas maksimal dan minimal progress animasi (berbeda tiap bentuk karena efek feather)
var min_progress: float = 0.0
var max_progress: float = 1.0

func _ready() -> void:
	_apply_preset() # Pastikan settingan material benar sejak awal
	
	# Pastikan saat mulai game transisinya kebuka (layar tembus pandang)
	shader_mat.set_shader_parameter("progress", max_progress)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_preset() -> void:
	if current_preset == TransitionPreset.CUSTOM:
		return # Jangan ubah apa-apa, pakai settingan Inspector
		
	# --- RESET KE DEFAULT DULU ---
	min_progress = 0.0
	max_progress = 1.0
	shader_mat.set_shader_parameter("position", Vector2(0, 0))
	shader_mat.set_shader_parameter("grid_size", Vector2(1, 1))
	shader_mat.set_shader_parameter("rotation_angle", 0.0)
	shader_mat.set_shader_parameter("stagger", Vector2(0, 0))
	shader_mat.set_shader_parameter("progress_bias", Vector2(0, 0))
	shader_mat.set_shader_parameter("edges", 4)
	shader_mat.set_shader_parameter("sectors", 1)
	shader_mat.set_shader_parameter("flip_frequency", Vector2i(1, 1))
	shader_mat.set_shader_parameter("global_x_mirror", false)
	shader_mat.set_shader_parameter("global_y_mirror", false)
	shader_mat.set_shader_parameter("local_x_mirror", false)
	shader_mat.set_shader_parameter("local_y_mirror", false)
	shader_mat.set_shader_parameter("invert", false)
	
	match current_preset:
		# --- BASIC ---
		TransitionPreset.SIMPLE_FADE:
			shader_mat.set_shader_parameter("transition_type", 0)
			shader_mat.set_shader_parameter("grid_size", Vector2(0, 0))
			shader_mat.set_shader_parameter("basic_feather", 1.0)
			min_progress = -0.5
			max_progress = 0.5
		TransitionPreset.LEFT_TO_RIGHT:
			shader_mat.set_shader_parameter("transition_type", 0)
			shader_mat.set_shader_parameter("grid_size", Vector2(1, 0))
			min_progress = -0.2
			max_progress = 2.2
		TransitionPreset.CENTER_WIPE:
			shader_mat.set_shader_parameter("transition_type", 0)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			min_progress = -0.2
			max_progress = 1.2
		TransitionPreset.BLINDER_WIPE:
			shader_mat.set_shader_parameter("transition_type", 0)
			shader_mat.set_shader_parameter("grid_size", Vector2(0, 5))
			min_progress = -0.2
			max_progress = 2.2
		TransitionPreset.GRID_REVEAL:
			shader_mat.set_shader_parameter("transition_type", 0)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("grid_size", Vector2(10, 10))
			min_progress = -0.2
			max_progress = 1.2
			
		# --- SHAPE ---
		TransitionPreset.IRIS_CIRCLE:
			shader_mat.set_shader_parameter("transition_type", 2)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("edges", 64)
			min_progress = -0.2
			max_progress = 1.7
		TransitionPreset.DIAMOND_SHAPE:
			shader_mat.set_shader_parameter("transition_type", 2)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("edges", 4)
			min_progress = -0.2
			max_progress = 1.7
		TransitionPreset.SCRATCH_LINES_REVEAL:
			shader_mat.set_shader_parameter("transition_type", 2)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("grid_size", Vector2(50, 5))
			shader_mat.set_shader_parameter("edges", 3)
			shader_mat.set_shader_parameter("flip_frequency", Vector2i(2, 1))
			min_progress = -0.2
			max_progress = 1.7
		TransitionPreset.OVERLAPPING_DIAMONDS:
			shader_mat.set_shader_parameter("transition_type", 2)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("grid_size", Vector2(50, 0.5))
			shader_mat.set_shader_parameter("edges", 3)
			shader_mat.set_shader_parameter("shape_feather", 0.0)
			min_progress = -0.2
			max_progress = 1.7
		TransitionPreset.SPIKE_TRAP:
			shader_mat.set_shader_parameter("transition_type", 2)
			shader_mat.set_shader_parameter("position", Vector2(0, 1.0))
			shader_mat.set_shader_parameter("grid_size", Vector2(1, 3))
			shader_mat.set_shader_parameter("rotation_angle", 30.0)
			shader_mat.set_shader_parameter("global_x_mirror", true)
			shader_mat.set_shader_parameter("local_y_mirror", true)
			shader_mat.set_shader_parameter("edges", 3)
			min_progress = -0.2
			max_progress = 2.7
			
		# --- CLOCK (Semuanya butuh Invert = true) ---
		TransitionPreset.CORNER_CLOCK:
			shader_mat.set_shader_parameter("transition_type", 3)
			shader_mat.set_shader_parameter("grid_size", Vector2(1, 1))
			shader_mat.set_shader_parameter("invert", true)
			min_progress = 0.0
			max_progress = 1.0
		TransitionPreset.CENTER_CLOCK:
			shader_mat.set_shader_parameter("transition_type", 3)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("grid_size", Vector2(1, 1))
			shader_mat.set_shader_parameter("invert", true)
			min_progress = 0.0
			max_progress = 1.0
		TransitionPreset.FAN_TRANSITION:
			shader_mat.set_shader_parameter("transition_type", 3)
			shader_mat.set_shader_parameter("grid_size", Vector2(1, 1))
			shader_mat.set_shader_parameter("sectors", 4)
			shader_mat.set_shader_parameter("invert", true)
			min_progress = 0.0
			max_progress = 1.0
		TransitionPreset.SEAMLESS_FLOWER:
			shader_mat.set_shader_parameter("transition_type", 3)
			shader_mat.set_shader_parameter("grid_size", Vector2(5, 5))
			shader_mat.set_shader_parameter("flip_frequency", Vector2i(2, 2))
			shader_mat.set_shader_parameter("sectors", 16)
			shader_mat.set_shader_parameter("invert", true)
			min_progress = 0.0
			max_progress = 1.0
		TransitionPreset.HOURGLASS_WIPE:
			shader_mat.set_shader_parameter("transition_type", 3)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("stagger", Vector2(1, 1))
			shader_mat.set_shader_parameter("flip_frequency", Vector2i(2, 2))
			shader_mat.set_shader_parameter("sectors", 2)
			shader_mat.set_shader_parameter("invert", true)
			min_progress = 0.0
			max_progress = 1.0
		TransitionPreset.DOUBLE_DIAMOND:
			shader_mat.set_shader_parameter("transition_type", 3)
			shader_mat.set_shader_parameter("position", Vector2(0.5, 0.5))
			shader_mat.set_shader_parameter("grid_size", Vector2(2, 2))
			shader_mat.set_shader_parameter("local_x_mirror", true)
			shader_mat.set_shader_parameter("local_y_mirror", true)
			shader_mat.set_shader_parameter("sectors", 4)
			shader_mat.set_shader_parameter("invert", true)
			min_progress = 0.0
			max_progress = 1.0


func play_transition() -> void:
	_apply_preset()
	# Blokir klik mouse selama transisi
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fase 1: Tutup Layar (Terbuka -> Tertutup / max_progress -> min_progress)
	var tween = create_tween()
	tween.tween_method(set_shader_progress, max_progress, min_progress, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	transition_halfway.emit()
	
	# Fase 2: Buka Layar (Tertutup -> Terbuka / min_progress -> max_progress)
	var tween2 = create_tween()
	tween2.tween_method(set_shader_progress, min_progress, max_progress, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tween2.finished
	
	# Buka blokir mouse
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()

# Fungsi bantuan khusus untuk masuk/keluar gedung (jika ingin dipisah)
func fade_in() -> void:
	# (Tidak perlu panggil _apply_preset di sini karena logikanya sudah dipanggil saat fade_out sebelumnya,
	# jadi layarnya tetap konsisten saat membuka)
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_method(set_shader_progress, min_progress, max_progress, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()

func fade_out() -> void:
	_apply_preset()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_method(set_shader_progress, max_progress, min_progress, transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	transition_halfway.emit()

func set_shader_progress(value: float) -> void:
	shader_mat.set_shader_parameter("progress", value)
