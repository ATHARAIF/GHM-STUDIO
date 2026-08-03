extends Camera3D

@export_group("Zoom")
@export var zoom_step: float = 0.5
@export var zoom_min: float = 3.0
@export var zoom_max: float = 15.0

@export_group("Pan")
@export var pan_speed: float = 1.0   # kalikan sensitivitas geser, 1.0 = 1:1 sama gerak mouse
@export var pan_bounds_min: Vector2 = Vector2(-10, -10)   # batas geser sumbu X/Z (dalam world unit)
@export var pan_bounds_max: Vector2 = Vector2(10, 10)
@export var excluded_area: Control   # klik di dalam area ini (misal CardHand) gak bakal ngegerakin kamera

var dragging: bool = false
var last_mouse_pos: Vector2

func _ready() -> void:
	# pastiin projection Orthogonal, biar "size" yang kepake buat zoom (bukan fov)
	projection = Camera3D.PROJECTION_ORTHOGONAL

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scroll_up"):
		_zoom(-zoom_step)
	elif event.is_action_pressed("scroll_down"):
		_zoom(zoom_step)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_in_excluded_area(event.position):
				return   # klik di area terlarang (misal CardHand) -- biarin Card yang handle, kamera diem
			dragging = true
			last_mouse_pos = event.position
		else:
			dragging = false

	if event is InputEventMouseMotion and dragging:
		var delta: Vector2 = event.position - last_mouse_pos
		last_mouse_pos = event.position
		_pan(delta)

func _is_in_excluded_area(screen_pos: Vector2) -> bool:
	if excluded_area == null:
		return false
	return excluded_area.get_global_rect().has_point(screen_pos)

func _zoom(amount: float) -> void:
	size = clamp(size + amount, zoom_min, zoom_max)

func _pan(mouse_delta: Vector2) -> void:
	# geser di bidang X/Z dunia (bukan X/Y layar), disesuaikan sama orientasi kamera isometric.
	# klik-drag ke kanan/atas di layar -> kamera geser berlawanan arah (kesan "narik" dunia).
	var right := global_transform.basis.x
	var forward := -global_transform.basis.z

	# proyeksiin biar geraknya cuma di bidang datar (Y tetap), gak ngangkat/nurunin kamera
	right.y = 0.0
	forward.y = 0.0
	right = right.normalized()
	forward = forward.normalized()

	var move := (-right * mouse_delta.x + forward * mouse_delta.y) * pan_speed * 0.01

	var new_pos: Vector3 = global_position + move
	new_pos.x = clamp(new_pos.x, pan_bounds_min.x, pan_bounds_max.x)
	new_pos.z = clamp(new_pos.z, pan_bounds_min.y, pan_bounds_max.y)

	global_position = new_pos
