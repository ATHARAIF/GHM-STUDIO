extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 12.0 

@onready var pivot: Camera3D = $SpringArm3D/Camera3D
# 👇 Jangan lupa sesuaikan nama node mesh lu di sini
@onready var visual_mesh: Node3D = $player

func _physics_process(delta: float) -> void:
	# Gravitasi
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Lompat
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
	var input_dir := Input.get_vector( "Left", "Right", "Up", "Down")
	
	# 👇 KUNCI PERUBAHAN: Pake global_transform.basis dari pivot kamera
	var direction := (pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Wajib di-nol-kan Y-nya biar karakter nggak amblas/terbang ngikutin kemiringan (pitch) kamera
	direction.y = 0
	direction = direction.normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Bikin mesh ngadep ke arah jalan dengan mulus
		var target_angle = atan2(direction.x, direction.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, ROTATION_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
