extends Node3D
class_name GroundTile

var is_occupied: bool = false
var placed_tile: Node3D = null
var grid_coord: Vector2i = Vector2i.ZERO

func occupy(tile: Node3D) -> void:
	is_occupied = true
	placed_tile = tile

func clear() -> void:
	is_occupied = false
	placed_tile = null
