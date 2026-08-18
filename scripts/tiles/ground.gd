extends Node3D

func _ready() -> void:
	get_viewport().physics_object_picking = true
	PlacementManager.register_camera($Camera3D)
	PlacementManager.register_ground_tiles(_get_ground_tiles())

func _get_ground_tiles() -> Array[GroundTile]:
	var tiles: Array[GroundTile] = []
	_collect_ground_tiles(self, tiles)
	return tiles

func _collect_ground_tiles(node: Node, tiles: Array[GroundTile]) -> void:
	for child in node.get_children():
		if child is GroundTile:
			tiles.append(child)
		_collect_ground_tiles(child, tiles)   # tetep turun walau child-nya sendiri GroundTile,
											   # jaga-jaga kalau ada nested group lagi di dalemnya
