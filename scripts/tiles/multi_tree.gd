@tool
extends MultiMeshInstance3D

# --- SETTING DI INSPECTOR ---

@export var glb_file: PackedScene :
	set(value):
		glb_file = value
		_generate_grid()

@export var grid_size: Vector2i = Vector2i(10, 5) :
	set(value):
		grid_size = value
		_generate_grid()

@export var spacing: Vector2 = Vector2(1.2, 1.2) :
	set(value):
		spacing = value
		_generate_grid()

# Default scale udah diset ke 0.08 sesuai kebutuhan
@export var custom_scale: Vector3 = Vector3(0.08, 0.08, 0.08) :
	set(value):
		custom_scale = value
		_generate_grid()

# Rotasi dalam bentuk derajat (degrees) biar gampang ngisinya
@export var custom_rotation: Vector3 = Vector3(0, 0, 0) :
	set(value):
		custom_rotation = value
		_generate_grid()


# --- LOGIKA AUTO-UPDATE & FIX PROPORSI ---

func _ready():
	_generate_grid()

func _generate_grid():
	if not glb_file:
		multimesh = null
		return
		
	var temp_scene = glb_file.instantiate()
	var mesh_target = null
	var original_transform = Transform3D()
	
	# Nyari Mesh dan ngambil Transform aslinya dari GLB biar gak melar
	for child in temp_scene.get_children():
		if child is MeshInstance3D:
			mesh_target = child.mesh
			original_transform = child.transform
			break
		# Jaga-jaga kalau dari Blender nge-group nodenya lebih dalem
		for grand_child in child.get_children():
			if grand_child is MeshInstance3D:
				mesh_target = grand_child.mesh
				# Gabungin transform parent dan child
				original_transform = child.transform * grand_child.transform
				break
				
	# Kalau mesh dan proporsi asli udah ketemu, susun multimesh-nya
	if mesh_target:
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = grid_size.x * grid_size.y
		mm.mesh = mesh_target 
		
		# Konversi input derajat dari Inspector ke Radian (karena Godot bacanya radian)
		var rot_rad = Vector3(
			deg_to_rad(custom_rotation.x),
			deg_to_rad(custom_rotation.y),
			deg_to_rad(custom_rotation.z)
		)
		
		var index = 0
		for x in range(grid_size.x):
			for z in range(grid_size.y):
				var pos = Vector3(x * spacing.x, 0, z * spacing.y)
				
				# Bikin Basis baru buat scale dan rotasi custom dari lu
				var custom_basis = Basis.from_euler(rot_rad).scaled(custom_scale)
				var custom_transform = Transform3D(custom_basis, pos)
				
				# Kalikan sama transform asli GLB biar proporsinya tetap ngikutin Blender
				var final_transform = custom_transform * original_transform
				
				mm.set_instance_transform(index, final_transform)
				index += 1
				
		multimesh = mm
		
	temp_scene.queue_free()
