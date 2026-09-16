extends Camera3D

@export_group("Panning")
## Kecepatan/sensitivitas saat menggeser layar menggunakan Mouse (Drag).
@export var pan_speed: float = 2.0
## Kecepatan menggeser layar pakai tombol WASD / Panah.
@export var keyboard_pan_speed: float = 15.0
## Tingkat kemulusan (lerp) saat berhenti. Angka kecil (5.0) = licin/nge-drift. Angka besar (25.0) = kaku/langsung berhenti.
@export var smooth_pan: float = 15.0
## Tombol mouse mana yang ditahan untuk geser. (0 = Middle Mouse, 1 = Right Mouse)
@export_enum("Middle Mouse", "Right Mouse") var pan_button: int = 0

@export_group("Zooming (Orthogonal)")
## Seberapa jauh kamera meloncat setiap kali putar roda mouse (scroll).
@export var zoom_speed: float = 2.0
## Batas Zoom In maksimal (Kamera paling dekat ke tanah).
@export var min_zoom: float = 3.0
## Batas Zoom Out maksimal (Kamera paling tinggi melihat luas peta).
@export var max_zoom: float = 20.0
## Tingkat kemulusan transisi saat scroll. Angka kecil (5.0) = empuk.
@export var smooth_zoom: float = 10.0
## Centang agar zoom in/out selalu mengarah ke posisi kursor mouse (Standar game modern).
@export var zoom_to_cursor: bool = true

@export_group("Map Bounds")
## Centang jika ingin mengurung kamera. Batas peta akan dihitung OTOMATIS berdasarkan apa yang terlihat di layar saat 'Max Zoom Out'.
@export var use_bounds: bool = true
## Faktor kompensasi batas otomatis. Jika saat Zoom In kamu masih bisa melihat area yang tidak terlihat saat Max Zoom Out (bocor), turunkan angka ini (misal ke 0.8, 0.5, atau 0.3).
@export var auto_limit_multiplier: float = 1.0

@export_subgroup("Manual Bounds")
## Centang jika ingin menggunakan batas jarak manual yang kaku (Kiri, Kanan, Atas, Bawah). 
## Rules bahwa "Max Zoom Out = tidak bisa digeser" akan TETAP berlaku. Batas di bawah ini mendefinisikan seberapa jauh kamu bisa geser saat Max Zoom In.
@export var use_manual_bounds: bool = false
## Jarak batas kiri layar (Berapa unit kamera boleh geser ke kiri dari posisi awal).
@export var manual_limit_left: float = 5.0
## Jarak batas kanan layar.
@export var manual_limit_right: float = 5.0
## Jarak batas atas layar.
@export var manual_limit_top: float = 5.0
## Jarak batas bawah layar.
@export var manual_limit_bottom: float = 5.0

var _target_size: float = 10.0
var _target_position: Vector3
var _is_panning: bool = false
var _last_mouse_pos: Vector2

var _initial_position: Vector3

func _ready() -> void:
	_target_size = size
	_target_position = global_position
	_initial_position = global_position # Jadikan posisi awal sebagai pusat (center)

func _unhandled_input(event: InputEvent) -> void:
	# Cek apakah ada popup aktif di layar. Jika ada, abaikan semua input kamera!
	var popups = [
		"MenuPanel", 
		"FarmlandDetailPopup", 
		"HarvestMethodPopup", 
		"HarvestResultPopup", 
		"PackagingPopup", 
		"ProcessingPopup", 
		"PruningPopup", 
		"RoastingPopup"
	]
	
	var tree = get_tree()
	if tree and tree.current_scene:
		# Cari semua CanvasLayer di dalam current_scene (termasuk anak-anak dari tile)
		var canvas_layers = tree.current_scene.find_children("*", "CanvasLayer", true, false)
		for layer in canvas_layers:
			var layer_name = str(layer.name)
			for p in popups:
				if p in layer_name and layer.visible:
					# Ada popup yang sedang terbuka (visible)!
					return
				
	if event is InputEventMouseButton:
		# --- Logika Zoom ---
		var prev_size = _target_size
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_size = clamp(_target_size - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_size = clamp(_target_size + zoom_speed, min_zoom, max_zoom)
			
		# Geser target posisi jika fitur Zoom to Cursor menyala (HANYA saat Zoom In)
		if zoom_to_cursor and _target_size != prev_size:
			var is_zooming_in = _target_size < prev_size
			var viewport_rect = get_viewport().get_visible_rect()
			var viewport_size = viewport_rect.size
			var center = viewport_size / 2.0
			
			var offset = Vector2.ZERO
			# Hanya bergeser ke kursor jika sedang Zoom In
			if is_zooming_in and viewport_rect.has_point(event.position):
				offset = event.position - center
			
			var ratio_diff = (prev_size - _target_size) / viewport_size.y
			var dx = offset.x * ratio_diff
			var dy = offset.y * ratio_diff
			
			var bx = global_transform.basis.x
			var by = global_transform.basis.y
			var bz = global_transform.basis.z
			
			# Rumus absolut persimpangan Raycast dengan bidang tanah (Y=0)
			if abs(bz.y) > 0.001:
				var shift = bx * dx - by * dy - bz * ((bx.y * dx - by.y * dy) / bz.y)
				_target_position += shift
			
		# --- Logika Panning Start/Stop ---
		var target_btn = MOUSE_BUTTON_MIDDLE if pan_button == 0 else MOUSE_BUTTON_RIGHT
		if event.button_index == target_btn:
			if event.pressed:
				_is_panning = true
				_last_mouse_pos = event.position
			else:
				_is_panning = false
				
	# --- Logika Panning Drag ---
	elif event is InputEventMouseMotion and _is_panning:
		var delta_mouse = event.position - _last_mouse_pos
		_last_mouse_pos = event.position
		
		var viewport_size = get_viewport().get_visible_rect().size
		var ratio = size / viewport_size.y
		
		var dx = delta_mouse.x * ratio * pan_speed
		var dy = delta_mouse.y * ratio * pan_speed
		
		var bx = global_transform.basis.x
		var by = global_transform.basis.y
		var bz = global_transform.basis.z
		
		# Gunakan rumus presisi yang sama untuk panning agar 100% lengket dengan kursor
		if abs(bz.y) > 0.001:
			var shift = bx * dx - by * dy - bz * ((bx.y * dx - by.y * dy) / bz.y)
			_target_position -= shift # Minus karena kita menggeser kamera ke arah berlawanan dari tarikan mouse

func _process(delta: float) -> void:
	# --- Keyboard Panning ---
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir != Vector2.ZERO:
		var cam_forward = -global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		
		var cam_right = global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		
		var pan_amount = keyboard_pan_speed * delta * (size / 10.0) 
		_target_position += cam_right * input_dir.x * pan_amount
		_target_position += -cam_forward * input_dir.y * pan_amount
		
	# --- Terapkan Batas Area Peta (Otomatis se-layar Max Zoom Out) ---
	if use_bounds:
		# Untuk mengatasi masalah batas diagonal pada kamera Isometric,
		# kita harus mengurung kamera dalam kotak yang searah dengan LAYAR (Screen Space), 
		# bukan searah dengan dunia 3D (World Space X/Z).
		
		var cam_forward = -global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		
		var cam_right = global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		
		# Jarak kamera saat ini dari titik tengah
		var offset = _target_position - _initial_position
		
		# Terjemahkan jarak tersebut ke sumbu layar (Kiri-Kanan Layar, Atas-Bawah Layar)
		var local_x = offset.dot(cam_right)
		var local_z = offset.dot(cam_forward)
		
		var viewport_size = get_viewport().get_visible_rect().size
		var aspect = viewport_size.x / viewport_size.y
		
		var lim_left = 0.0
		var lim_right = 0.0
		var lim_top = 0.0
		var lim_bottom = 0.0
		
		if use_manual_bounds:
			# Skala 0.0 (Max Zoom Out) sampai 1.0 (Max Zoom In)
			# Memastikan rules "semakin zoom out, semakin gak bisa digeser" tetap berlaku!
			var zoom_factor = clamp((max_zoom - size) / max(0.01, max_zoom - min_zoom), 0.0, 1.0)
			
			lim_left = -manual_limit_left * zoom_factor
			lim_right = manual_limit_right * zoom_factor
			lim_top = manual_limit_top * zoom_factor
			lim_bottom = -manual_limit_bottom * zoom_factor
		else:
			# Batas otomatis
			var auto_lim_z = (max_zoom - size) * auto_limit_multiplier
			var move_limit_x = auto_lim_z * aspect
			lim_left = -move_limit_x
			lim_right = move_limit_x
			lim_top = auto_lim_z
			lim_bottom = -auto_lim_z
		
		# Kurung pergerakan di sumbu layar
		local_x = clamp(local_x, lim_left, lim_right)
		local_z = clamp(local_z, lim_bottom, lim_top)
		
		# Kembalikan ke koordinat dunia 3D (World Space)
		_target_position.x = _initial_position.x + (cam_right.x * local_x) + (cam_forward.x * local_z)
		_target_position.z = _initial_position.z + (cam_right.z * local_x) + (cam_forward.z * local_z)
		
	# --- Smooth Interpolation (Lerp) ---
	global_position = global_position.lerp(_target_position, smooth_pan * delta)
	size = lerp(size, _target_size, smooth_zoom * delta)
