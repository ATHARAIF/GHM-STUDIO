@tool
extends Node3D

@export var tile_size: float = 2.0
@export var ground_material: StandardMaterial3D
@export var border_material: StandardMaterial3D

@export var coordinates: Array[Vector2] = [Vector2(0,0)]:
	set(val):
		coordinates = val

@export var generate_now: bool = false:
	set(val):
		if val:
			_generate_shape()
			generate_now = false

func _generate_shape():
	for child in get_children():
		child.queue_free()
		
	print("Generating shape with ", coordinates.size(), " tiles...")
	
	for coord in coordinates:
		var tile_info = _get_tile_info(coord)
		var file_name = tile_info["file"]
		var rot_deg = tile_info["rot"]
		
		var tile_scene = load("res://assets/3D/tiles/base_tiles/" + file_name + ".glb")
		if tile_scene:
			var inst = tile_scene.instantiate()
			inst.position = Vector3(coord.x * tile_size, 0, coord.y * tile_size)
			# Apply rotation around Y axis
			inst.rotation_degrees = Vector3(0, rot_deg, 0)
			add_child(inst)
			
			if inst.get_child_count() > 0:
				var ground = inst.get_child(0)
				if ground is MeshInstance3D and ground_material:
					ground.material_override = ground_material
				for i in range(ground.get_child_count()):
					var border = ground.get_child(i)
					if border is MeshInstance3D and border_material:
						border.material_override = border_material
						
	print("Generation complete!")

# Algoritma Cerdas untuk mencari bentuk dan rotasi yang pas
func _get_tile_info(coord: Vector2) -> Dictionary:
	var n = coordinates.has(coord + Vector2(0, -1))
	var s = coordinates.has(coord + Vector2(0, 1))
	var e = coordinates.has(coord + Vector2(1, 0))
	var w = coordinates.has(coord + Vector2(-1, 0))
	
	var ne = coordinates.has(coord + Vector2(1, -1))
	var nw = coordinates.has(coord + Vector2(-1, -1))
	var se = coordinates.has(coord + Vector2(1, 1))
	var sw = coordinates.has(coord + Vector2(-1, 1))
	
	var ortho_count = int(n) + int(s) + int(e) + int(w)
	
	# KALIBRASI ARAH (Berdasarkan Screenshot):
	# rot 0   = Utara / North (Z-)
	# rot 90  = Barat / West (X-)
	# rot 180 = Selatan / South (Z+)
	# rot -90 = Timur / East (X+)
	
	if ortho_count == 0:
		return {"file": "full_border", "rot": 0}
	
	# UJUNG BUNTU (Punya 1 tetangga, 3 sisi ditutup)
	if ortho_count == 1:
		if n: return {"file": "3side_border", "rot": 0}
		if w: return {"file": "3side_border", "rot": 90}
		if s: return {"file": "3side_border", "rot": 180}
		if e: return {"file": "3side_border", "rot": -90}
		
	# LORONG / POJOKAN LUAR (Punya 2 tetangga)
	if ortho_count == 2:
		# Lorong lurus
		if e and w: return {"file": "2side_border", "rot": 0}
		if n and s: return {"file": "2side_border", "rot": 90}
		
		# Pojokan (Asumsi rot=0 adalah sudut Kiri-Atas / NW tertutup)
		if s and e: return {"file": "corner_border", "rot": 0}   # Butuh tembok di NW
		if e and n: return {"file": "corner_border", "rot": 90}  # Butuh tembok di SW
		if n and w: return {"file": "corner_border", "rot": 180} # Butuh tembok di SE
		if w and s: return {"file": "corner_border", "rot": -90} # Butuh tembok di NE
			
	# SISI LURUS DENGAN POTENSI INNER CORNER (Punya 3 tetangga)
	if ortho_count == 3:
		# Punya E, S, W -> Tembok ada di Utara
		if e and s and w:
			if not se and not sw: return {"file": "1side_2corner", "rot": 0}
			if not sw: return {"file": "1side_1corner_1", "rot": 0}
			if not se: return {"file": "1side_1corner_2", "rot": 0}
			return {"file": "1side_border", "rot": 0}
			
		# Punya N, S, E -> Tembok ada di Barat
		if n and s and e:
			if not nw and not sw: return {"file": "1side_2corner", "rot": 90}
			if not nw: return {"file": "1side_1corner_1", "rot": 90}
			if not sw: return {"file": "1side_1corner_2", "rot": 90}
			return {"file": "1side_border", "rot": 90}
			
		# Punya W, N, E -> Tembok ada di Selatan
		if w and n and e:
			if not nw and not ne: return {"file": "1side_2corner", "rot": 180}
			if not ne: return {"file": "1side_1corner_1", "rot": 180}
			if not nw: return {"file": "1side_1corner_2", "rot": 180}
			return {"file": "1side_border", "rot": 180}
			
		# Punya N, S, W -> Tembok ada di Timur
		if n and s and w:
			if not ne and not se: return {"file": "1side_2corner", "rot": -90}
			if not se: return {"file": "1side_1corner_1", "rot": -90}
			if not ne: return {"file": "1side_1corner_2", "rot": -90}
			return {"file": "1side_border", "rot": -90}
			
	# TENGAH BANGUNAN (Punya 4 tetangga, cek diagonalnya)
	if ortho_count == 4:
		var missing = 0
		if not ne: missing += 1
		if not se: missing += 1
		if not sw: missing += 1
		if not nw: missing += 1
		
		if missing == 0: return {"file": "no_border", "rot": 0}
		if missing == 1:
			if not nw: return {"file": "1corner", "rot": 0}
			if not sw: return {"file": "1corner", "rot": 90}
			if not se: return {"file": "1corner", "rot": 180}
			if not ne: return {"file": "1corner", "rot": -90}
		if missing == 2:
			if not nw and not ne: return {"file": "2corner", "rot": 0}
			if not nw and not sw: return {"file": "2corner", "rot": 90}
			if not sw and not se: return {"file": "2corner", "rot": 180}
			if not se and not ne: return {"file": "2corner", "rot": -90}
			if not nw and not se: return {"file": "2corner_diagonal", "rot": 0}
			if not ne and not sw: return {"file": "2corner_diagonal", "rot": 90}
		if missing == 3:
			if se: return {"file": "3corner", "rot": 0}
			if ne: return {"file": "3corner", "rot": 90}
			if nw: return {"file": "3corner", "rot": 180}
			if sw: return {"file": "3corner", "rot": -90}
		if missing == 4:
			return {"file": "4corner", "rot": 0}
			
	return {"file": "no_border", "rot": 0}
