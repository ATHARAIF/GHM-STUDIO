extends Node

@export_group("Ghost Visual")
## Tingkat transparansi (0-1) objek 3D bayangan saat melayang di udara.
@export var ghost_float_alpha: float = 0.55
## Tingkat transparansi (0-1) area/kotak indikator penempatan di tanah.
@export var ghost_indicator_alpha: float = 0.25
## Warna indikator jika posisi penempatan valid (bisa ditaruh).
@export var valid_color: Color = Color(0.3, 1, 0.3)
## Warna indikator jika posisi penempatan tidak valid (merah/silang).
@export var invalid_color: Color = Color(1, 0.3, 0.3)

@export_group("Animation")
## Durasi animasi memutar arah bayangan (detik).
@export var rotate_duration: float = 0.2

var ghost_float: Node3D
var ghost_indicator: Node3D
var ghost_float_rotate_tween: Tween
var ghost_indicator_rotate_tween: Tween

var current_tile_scene: PackedScene

func update_ghost(scene: PackedScene, rotation_steps: int, visual_rot: float, float_pos: Vector3, indicator_pos: Vector3, valid: bool) -> void:
	if current_tile_scene != scene:
		clear_ghost()
		current_tile_scene = scene
		
	if ghost_float == null:
		ghost_float = scene.instantiate()
		_apply_native_transparency(ghost_float, ghost_float_alpha)
		ghost_float.rotation_degrees.y = visual_rot
		get_tree().current_scene.add_child(ghost_float)
		
	if ghost_indicator == null:
		ghost_indicator = scene.instantiate()
		_strip_to_base_tile(ghost_indicator)
		_make_flat_shadow(ghost_indicator, ghost_indicator_alpha)
		ghost_indicator.rotation_degrees.y = visual_rot
		get_tree().current_scene.add_child(ghost_indicator)
		
	ghost_indicator.global_position = indicator_pos
	ghost_float.global_position = float_pos
	
	_tint_shadow(ghost_indicator, not valid)

func animate_rotation(start_rot: float, target_rot: float) -> void:
	if ghost_float:
		if ghost_float_rotate_tween:
			ghost_float_rotate_tween.kill()
		ghost_float_rotate_tween = create_tween()
		ghost_float_rotate_tween.set_trans(Tween.TRANS_BACK)
		ghost_float_rotate_tween.set_ease(Tween.EASE_OUT)
		ghost_float_rotate_tween.tween_method(_set_ghost_float_rotation, start_rot, target_rot, rotate_duration)
		
	if ghost_indicator:
		if ghost_indicator_rotate_tween:
			ghost_indicator_rotate_tween.kill()
		ghost_indicator_rotate_tween = create_tween()
		ghost_indicator_rotate_tween.set_trans(Tween.TRANS_BACK)
		ghost_indicator_rotate_tween.set_ease(Tween.EASE_OUT)
		ghost_indicator_rotate_tween.tween_method(_set_ghost_indicator_rotation, start_rot, target_rot, rotate_duration)

func _set_ghost_float_rotation(value: float) -> void:
	if ghost_float:
		ghost_float.rotation_degrees.y = value

func _set_ghost_indicator_rotation(value: float) -> void:
	if ghost_indicator:
		ghost_indicator.rotation_degrees.y = value

func clear_ghost() -> void:
	if ghost_float:
		ghost_float.queue_free()
		ghost_float = null
	if ghost_indicator:
		ghost_indicator.queue_free()
		ghost_indicator = null
	ghost_float_rotate_tween = null
	ghost_indicator_rotate_tween = null
	current_tile_scene = null

func _find_base_tile_node(node: Node) -> Node3D:
	for child in node.get_children():
		if child.name == "base_tiles" and child is Node3D:
			return child
		var found := _find_base_tile_node(child)
		if found:
			return found
	return null

func _strip_to_base_tile(root: Node3D) -> void:
	var base := _find_base_tile_node(root)
	if base == null or base == root:
		return
	var keep_chain: Array[Node] = []
	var n: Node = base
	while n != null:
		keep_chain.append(n)
		if n == root:
			break
		n = n.get_parent()
	_prune_except(root, base, keep_chain)
	
func _prune_except(node: Node, base: Node3D, keep_chain: Array[Node]) -> void:
	for child in node.get_children():
		if child == base:
			continue
		if keep_chain.has(child):
			_prune_except(child, base, keep_chain)
		else:
			child.free()

func _apply_native_transparency(node: Node, alpha: float) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			child.transparency = 1.0 - alpha
		_apply_native_transparency(child, alpha)

func _make_flat_shadow(node: Node, alpha: float) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(valid_color.r, valid_color.g, valid_color.b, alpha)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			child.material_override = mat
			child.set_meta("shadow_mat", mat)
			child.set_meta("shadow_alpha", alpha)
		_make_flat_shadow(child, alpha)

func _tint_shadow(node: Node, invalid: bool) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.has_meta("shadow_mat"):
			var alpha: float = child.get_meta("shadow_alpha")
			var color: Color = invalid_color if invalid else valid_color
			child.get_meta("shadow_mat").albedo_color = Color(color.r, color.g, color.b, alpha)
		_tint_shadow(child, invalid)
