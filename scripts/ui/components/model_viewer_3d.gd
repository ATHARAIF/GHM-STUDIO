extends SubViewportContainer

@onready var item_anchor = $SubViewport/anchor
@onready var camera = $SubViewport/Camera3D
@onready var reset_button = $"../Button" # Menggunakan "../" jika posisi tombol sejajar di luar kontainer

# Menyimpan posisi awal kamera bawaan editor
var initial_camera_pos: Vector3

# === PENGATURAN ROTATION (KLIK KIRI + DRAG) ===
@export var rotation_sensitivity: float = 0.005
var is_dragging: bool = false

# === PENGATURAN ZOOM (SCROLL MOUSE) ===
@export var zoom_speed: float = 0.1
@export var zoom_min: float = 0.1  # Batas paling DEKAT (Detail Objek)
@export var zoom_max: float = 0.9  # Batas paling JAUH (Default Tampilan Awal)

# === PENGATURAN PANNING (KLIK TENGAH MOUSE + DRAG) ===
@export var pan_sensitivity: float = 0.003
@export var pan_max_limit_x: float = 1.5  # Batas geser horizontal maksimal saat zoom-in
@export var pan_max_limit_y: float = 2.0  # Batas geser vertikal maksimal saat zoom-in
var is_panning: bool = false

# === PENGATURAN TINGGI MODEL (SOLUSI KAMERA TURUN) ===
# Naikkan angka ini di Inspector jika objek silo masih terlalu merosot ke bawah
@export var item_vertical_offset: float = 0.7 

func _ready():
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	initial_camera_pos = camera.position
	
	# Hubungkan signal tombol reset otomatis
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)

func _gui_input(event):
	# === 1. LOGIKA ROTASI ===
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
		
	if event is InputEventMouseMotion and is_dragging:
		if item_anchor.get_child_count() > 0:
			item_anchor.rotate_y(event.relative.x * rotation_sensitivity)

	# === 2. LOGIKA PANNING (HANYA AKTIF SAAT ZOOM IN) ===
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		is_panning = event.pressed
		
	if event is InputEventMouseMotion and is_panning:
		if camera.size >= zoom_max:
			return
			
		var current_pan_speed = pan_sensitivity * camera.size
		camera.position.x -= event.relative.x * current_pan_speed
		camera.position.y += event.relative.y * current_pan_speed
		
		var max_limit_x = remap(camera.size, zoom_max, zoom_min, 0.0, pan_max_limit_x)
		var max_limit_y = remap(camera.size, zoom_max, zoom_min, 0.0, pan_max_limit_y)
		
		# Clamp posisi kamera dengan memperhitungkan posisi kamera yang sudah disesuaikan offset Y-nya
		var adjusted_initial_y = initial_camera_pos.y - item_vertical_offset
		camera.position.x = clampf(camera.position.x, initial_camera_pos.x - max_limit_x, initial_camera_pos.x + max_limit_x)
		camera.position.y = clampf(camera.position.y, adjusted_initial_y - max_limit_y, adjusted_initial_y + max_limit_y)

	# === 3. LOGIKA ZOOM ===
	if event is InputEventMouseButton:
		var new_size = camera.size
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			new_size -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			new_size += zoom_speed
			
		camera.size = max(0.1, clampf(new_size, zoom_min, zoom_max))
		
		if camera.size >= zoom_max:
			# Jika zoom out maksimal, kembalikan kamera ke posisi tengah default (termasuk offset Y)
			camera.position.x = initial_camera_pos.x
			camera.position.y = initial_camera_pos.y - item_vertical_offset
			camera.position.z = initial_camera_pos.z
		else:
			var max_limit_x = remap(camera.size, zoom_max, zoom_min, 0.0, pan_max_limit_x)
			var max_limit_y = remap(camera.size, zoom_max, zoom_min, 0.0, pan_max_limit_y)
			var adjusted_initial_y = initial_camera_pos.y - item_vertical_offset
			camera.position.x = clampf(camera.position.x, initial_camera_pos.x - max_limit_x, initial_camera_pos.x + max_limit_x)
			camera.position.y = clampf(camera.position.y, adjusted_initial_y - max_limit_y, adjusted_initial_y + max_limit_y)

func _process(delta):
	if not is_dragging and not is_panning and item_anchor.get_child_count() > 0:
		item_anchor.rotate_y(0.5 * delta)

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_node_ready() and visible:
			reset_preview()

# Fungsi reset yang menurunkan posisi kamera agar objek terlihat naik ke tengah layar
func reset_preview():
	if item_anchor:
		item_anchor.rotation = Vector3.ZERO
		item_anchor.position = Vector3.ZERO 
	if camera:
		camera.position.x = initial_camera_pos.x
		camera.position.z = initial_camera_pos.z
		# Trik: Turunkan posisi Y kamera agar objek silo terlihat naik ke tengah layar
		camera.position.y = initial_camera_pos.y - item_vertical_offset
		camera.size = zoom_max

func _on_reset_button_pressed():
	reset_preview()

# Fungsi panggil dari skrip luar untuk memunculkan item secara dinamis
func display_item_preview(item_scene_path: String, custom_y_offset: float = 0.0):
	for child in item_anchor.get_children():
		child.queue_free()
	
	if ResourceLoader.exists(item_scene_path):
		var new_item = load(item_scene_path).instantiate()
		item_anchor.add_child(new_item)
		new_item.position = Vector3.ZERO
		new_item.position.y += custom_y_offset
	
	reset_preview()

func update_packaging_preview(tipe: String, material: String, gramasi: float) -> void:
	if tipe == "" or material == "":
		for child in item_anchor.get_children():
			child.queue_free()
		return
		
	var type_str = ""
	if tipe == "pouch": type_str = "standing_pouch"
	elif tipe == "f_bottom": type_str = "flat_bottom"
	elif tipe == "gusset": type_str = "side_gusset"
	
	var mat_str = ""
	if material == "plastic":
		if tipe == "pouch": mat_str = "plasic" # Typo di file asli
		else: mat_str = "plastic"
	elif material == "paper":
		mat_str = "paper"
	elif material == "alumunium":
		if tipe == "gusset": mat_str = "aluvoi" # Typo di file asli
		else: mat_str = "aluvo"
		
	var y_offset = 0.0
	if type_str != "" and mat_str != "":
		# Geser Y pada modelnya sendiri, tanpa menyentuh kamera atau Inspector
		if type_str == "flat_bottom":
			y_offset = -0.05
		elif type_str == "side_gusset":
			y_offset = -0.05
			
		var path = "res://assets/3D/packaging/%s_%s.glb" % [type_str, mat_str]
		display_item_preview(path, y_offset)
		
	# Update Scaling (-0.15 per size step)
	var scale_factor = 1.0
	if gramasi == 1000.0: scale_factor = 1.0
	elif gramasi == 500.0: scale_factor = 0.85
	elif gramasi == 200.0: scale_factor = 0.70
	elif gramasi == 100.0: scale_factor = 0.55
	
	if scale_factor <= 0: scale_factor = 1.0
	item_anchor.scale = Vector3(scale_factor, scale_factor, scale_factor)
