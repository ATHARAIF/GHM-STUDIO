class_name PlacedItem
extends StaticBody3D

## Attach ke root node "PlacedItem" (StaticBody3D). Struktur node:
##
## PlacedItem (StaticBody3D, script ini)
## ├── MeshInstance3D   -- dipake pas dummy box (ItemData.model_scene kosong)
## └── CollisionShape3D
##
## Ukuran dummy/collision otomatis ngikutin ItemData.footprint_size (dalam
## satuan tile, UNROTATED -- rotasi diurus lewat rotation.y node ini sendiri
## oleh WarehousePlacement, bukan di sini).
##
## Setiap item (dummy ATAU model custom) otomatis dikasih "base plate" --
## alas + border tipis di bawahnya, warnanya ngikutin ItemData.category
## ("storage" / "rooms"). Model/dummy-nya otomatis didudukin DI ATAS plate
## ini (bukan langsung di lantai polos).

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var item_data: ItemData
var _highlight_targets: Array[MeshInstance3D] = []
var _is_custom_model: bool = false

func setup(data: ItemData, tile_size: float) -> void:
	item_data = data
	_highlight_targets.clear()

	var plate_top_y := 0.0
	if not data.model_includes_own_plate:
		plate_top_y = _add_base_plate(data, tile_size)

	if data.model_scene != null:
		_setup_custom_model(data, tile_size, plate_top_y)
	else:
		_setup_dummy(data, tile_size, plate_top_y)

	set_selected(false)

const PLATE_SCENE: PackedScene = preload("res://assets/3D/tiles/base_tiles/no_border.glb")  # sesuaikan path

## Warna plate berdasarkan kategori item. Tambahin case baru di sini kalau
## nanti ada kategori lain.
func _category_color(category: String) -> Color:
	match category:
		"storage":
			return Color(0.55, 0.35, 0.22)  # coklat
		"rooms":
			return Color(0.30, 0.42, 0.55)  # biru keabuan
		_:
			return Color(0.5, 0.5, 0.5)

## Instance "no_border.glb" sebagai alas di bawah item, di-fit skalanya
## biar pas muat di area footprint, terus ditint warnanya sesuai kategori.
## Return posisi Y di puncak plate -- itu yang jadi "lantai baru" buat
## naro model/dummy item di atasnya.
func _add_base_plate(data: ItemData, tile_size: float) -> float:
	var plate := PLATE_SCENE.instantiate()
	add_child(plate)

	var target_width: float = float(data.footprint_size.x) * tile_size
	var target_depth: float = float(data.footprint_size.y) * tile_size
	_auto_fit_node(plate, target_width, target_depth)
	_center_model_xz(plate)
	_ground_model(plate, 0.0)  # alas plate nempel di y=0 (lantai)
	_tint_node(plate, _category_color(data.category))

	var plate_aabb := _compute_local_aabb(plate)
	return plate_aabb.position.y + plate_aabb.size.y  # puncak plate

func _tint_node(node: Node, color: Color) -> void:
	for mesh in _find_mesh_instances(node):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mesh.material_override = mat

func _setup_dummy(data: ItemData, tile_size: float, plate_top_y: float) -> void:
	_is_custom_model = false
	mesh_instance.visible = true

	var width: float = float(data.footprint_size.x) * tile_size - 0.2
	var depth: float = float(data.footprint_size.y) * tile_size - 0.2

	var box := BoxMesh.new()
	box.size = Vector3(width, 0.3, depth)
	mesh_instance.mesh = box
	mesh_instance.position = Vector3(0.0, plate_top_y + box.size.y * 0.5, 0.0)

	var shape := BoxShape3D.new()
	shape.size = box.size
	collision_shape.shape = shape
	collision_shape.position = mesh_instance.position

	_add_front_marker(box.size, plate_top_y)
	_highlight_targets.append(mesh_instance)

func _setup_custom_model(data: ItemData, tile_size: float, plate_top_y: float) -> void:
	_is_custom_model = true
	mesh_instance.visible = false

	var model := data.model_scene.instantiate()
	add_child(model)

	if data.model_includes_own_plate:
		# Scene ini udah komplit (plate + model, di-scale/posisiin manual
		# di editor) -- pasang APA ADANYA, jangan diotak-atik lagi.
		pass
	else:
		if model is Node3D:
			var model3d := model as Node3D
			model3d.scale = data.model_scale
			model3d.rotation_degrees.y = data.model_rotation_offset

		if data.auto_fit_to_footprint:
			_auto_fit_model(model, data, tile_size)
			_auto_fit_height(model, data.target_height)

		_center_model_xz(model)              # geser biar TENGAH model pas di tengah footprint
		_ground_model(model, plate_top_y)    # geser biar ALAS model nempel pas di ATAS plate

		if model is Node3D:
			(model as Node3D).position.y += data.model_y_offset

	var shape := BoxShape3D.new()
	shape.size = Vector3(
		float(data.footprint_size.x) * tile_size,
		data.collision_height,
		float(data.footprint_size.y) * tile_size
	)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0.0, plate_top_y + data.collision_height * 0.5, 0.0)

	_highlight_targets = _find_mesh_instances(model)

## Gabungan AABB semua mesh di dalam model, dalam LOCAL SPACE PlacedItem ini
## (jadi udah include efek scale/rotasi/posisi model sekarang).
func _compute_local_aabb(model: Node) -> AABB:
	var meshes := _find_mesh_instances(model)
	if meshes.is_empty():
		return AABB()

	var combined: AABB = global_transform.affine_inverse() * (meshes[0].global_transform * meshes[0].get_aabb())
	for i in range(1, meshes.size()):
		var local_aabb: AABB = global_transform.affine_inverse() * (meshes[i].global_transform * meshes[i].get_aabb())
		combined = combined.merge(local_aabb)
	return combined

## Skalain model (uniform, jaga aspect ratio) biar pas muat di area
## footprint_size * tile_size. Dipanggil SEBELUM centering & grounding.
## Buat MODEL ITEM: uniform scale, JAGA proporsi asli (nggak digepengin).
## Efeknya mungkin nggak 100% ngisi penuh footprint kalau proporsi model
## beda dari rasio footprint -- itu lebih baik daripada bentuknya rusak.
func _auto_fit_model(model: Node, data: ItemData, tile_size: float) -> void:
	if not (model is Node3D):
		return
	var aabb := _compute_local_aabb(model)
	if aabb.size.x <= 0.0 or aabb.size.z <= 0.0:
		return

	var target_width: float = float(data.footprint_size.x) * tile_size
	var target_depth: float = float(data.footprint_size.y) * tile_size

	var scale_x: float = target_width / aabb.size.x
	var scale_z: float = target_depth / aabb.size.z
	var uniform_scale: float = minf(scale_x, scale_z)

	(model as Node3D).scale *= uniform_scale

## Buat PLATE (no_border.glb): non-uniform (X & Z independen), sengaja
## BUKAN jaga aspect ratio -- soalnya plate itu cuma kotak polos, aman
## diregangin biar selalu ngisi PENUH area footprint tanpa nyisa kosong.
func _auto_fit_node(node: Node, target_width: float, target_depth: float) -> void:
	if not (node is Node3D):
		return
	var aabb := _compute_local_aabb(node)
	if aabb.size.x <= 0.0 or aabb.size.z <= 0.0:
		return

	var scale_x: float = target_width / aabb.size.x
	var scale_z: float = target_depth / aabb.size.z

	# Non-uniform (X & Z independen) sengaja, BUKAN jaga aspect ratio --
	# biar item selalu ngisi PENUH area footprint-nya, nggak nyisa kotak
	# kosong kalau proporsi model aslinya beda dari rasio footprint (mis.
	# model kotak dipaksa masuk footprint 2x1).
	var node3d := node as Node3D
	node3d.scale.x *= scale_x
	node3d.scale.z *= scale_z

## Skalain tinggi (Y) model biar sesuai target_height, independen dari
## auto-fit lebar/kedalaman (_auto_fit_node cuma nyentuh X/Z).
func _auto_fit_height(node: Node, target_height: float) -> void:
	if not (node is Node3D):
		return
	var aabb := _compute_local_aabb(node)
	if aabb.size.y <= 0.0:
		return
	var scale_y: float = target_height / aabb.size.y
	(node as Node3D).scale.y *= scale_y

## Geser model (secara lokal) di sumbu X/Z biar TITIK TENGAH bounding box-nya
## pas di (0,0) -- yaitu titik tengah footprint-nya sendiri.
func _center_model_xz(model: Node) -> void:
	if not (model is Node3D):
		return
	var aabb := _compute_local_aabb(model)
	if aabb.size == Vector3.ZERO:
		return

	var center_x := aabb.position.x + aabb.size.x * 0.5
	var center_z := aabb.position.z + aabb.size.z * 0.5

	var model3d := model as Node3D
	model3d.position.x -= center_x
	model3d.position.z -= center_z

## Geser model (secara lokal) di sumbu Y biar titik PALING BAWAH mesh nempel
## pas di puncak plate (plate_top_y), bukan langsung di y=0.
func _ground_model(model: Node, plate_top_y: float) -> void:
	if not (model is Node3D):
		return
	var aabb := _compute_local_aabb(model)
	if aabb.size == Vector3.ZERO:
		return

	(model as Node3D).position.y += plate_top_y - aabb.position.y

func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result

func _add_front_marker(box_size: Vector3, plate_top_y: float) -> void:
	var marker := MeshInstance3D.new()
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(box_size.x * 0.6, 0.06, 0.12)
	marker.mesh = marker_mesh
	var marker_mat := StandardMaterial3D.new()
	marker_mat.albedo_color = Color(0.1, 0.1, 0.1)
	marker.material_override = marker_mat
	marker.position = Vector3(0.0, plate_top_y + box_size.y + 0.03, box_size.z * 0.5 - 0.1)
	add_child(marker)

func set_selected(value: bool) -> void:
	if _is_custom_model:
		if value:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.85, 0.2)
			for mesh in _highlight_targets:
				mesh.material_override = mat
		else:
			for mesh in _highlight_targets:
				mesh.material_override = null
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.2) if value else Color(0.8, 0.8, 0.8)
		for mesh in _highlight_targets:
			mesh.material_override = mat
