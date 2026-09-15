@tool
extends MultiMeshInstance3D

# --- SETTING DI INSPECTOR ---

## File Model 3D (.glb / .tscn) dari satu pohon yang akan digandakan.
@export var glb_file: PackedScene :
	set(value):
		glb_file = value
		_generate_grid()

## Jumlah grid/pohon (X dan Y) yang akan ditanam dalam area ini (misal: 10x5 pohon).
@export var grid_size: Vector2i = Vector2i(10, 5) :
	set(value):
		grid_size = value
		_generate_grid()

## Jarak renggang antar pohon pada sumbu X dan Z.
@export var spacing: Vector2 = Vector2(1.2, 1.2) :
	set(value):
		spacing = value
		_generate_grid()

# Default scale udah diset ke 0.08 sesuai kebutuhan
## Ukuran skala (Scale) 3D dari masing-masing pohon.
@export var custom_scale: Vector3 = Vector3(0.08, 0.08, 0.08) :
	set(value):
		custom_scale = value
		_generate_grid()

# Rotasi dalam bentuk derajat (degrees) biar gampang ngisinya
## Rotasi bawaan (Rotation) 3D dari masing-masing pohon (dalam derajat).
@export var custom_rotation: Vector3 = Vector3(0, 0, 0) :
	set(value):
		custom_rotation = value
		_generate_grid()

# --- TAMBAHAN FITUR RANDOM ---
@export_group("Randomization")
## Centang untuk mengacak arah rotasi pohon secara otomatis agar terlihat natural.
@export var enable_random_rotation: bool = false :
	set(value):
		enable_random_rotation = value
		_generate_grid()

# Range seberapa jauh objek boleh muter acak (dalam derajat)
# Misal Y diisi 180, nanti tiap objek bakal punya rotasi Y acak antara -180 sampai 180
## Batas rotasi acak maksimum (dalam derajat) jika fitur acak diaktifkan.
@export var random_rotation_range: Vector3 = Vector3(0, 180, 0) :
	set(value):
		random_rotation_range = value
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
		
		var index = 0
		for x in range(grid_size.x):
			for z in range(grid_size.y):
				var pos = Vector3(x * spacing.x, 0, z * spacing.y)
				
				# 1. Kalkulasi Rotasi Akhir (Custom + Random)
				var final_rot_deg = custom_rotation
				if enable_random_rotation:
					final_rot_deg.x += randf_range(-random_rotation_range.x, random_rotation_range.x)
					final_rot_deg.y += randf_range(-random_rotation_range.y, random_rotation_range.y)
					final_rot_deg.z += randf_range(-random_rotation_range.z, random_rotation_range.z)
				
				var rot_rad = Vector3(
					deg_to_rad(final_rot_deg.x),
					deg_to_rad(final_rot_deg.y),
					deg_to_rad(final_rot_deg.z)
				)
				
				# 2. Fix Rotasi Objeknya (Bukan Origin Grid)
				# Kita cuma ngambil rotasi aslinya (.basis) dan digabung sama rotasi/skala custom
				var custom_basis = Basis.from_euler(rot_rad).scaled(custom_scale)
				var final_basis = custom_basis * original_transform.basis
				
				# 3. Terapin Transform Akhir
				# Masukin basis rotasi yang udah bener ke koordinat grid (pos), origin asli GLB diabaikan biar gak ngorbit
				var final_transform = Transform3D(final_basis, pos)
				mm.set_instance_transform(index, final_transform)
				index += 1
				
		multimesh = mm
		
	temp_scene.queue_free()
