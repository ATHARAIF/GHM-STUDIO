@tool
extends Node3D
class_name GroundTile

@export var is_locked: bool = false:
	set(value):
		is_locked = value
		if is_inside_tree() and has_node("LockCover"):
			$LockCover.visible = is_locked

var is_occupied: bool = false
var placed_tile: Node3D = null
var grid_coord: Vector2i = Vector2i.ZERO

func _ready():
	# Sync visual with variable on load
	if has_node("LockCover"):
		$LockCover.visible = is_locked

func occupy(tile: Node3D) -> void:
	is_occupied = true
	placed_tile = tile

func clear() -> void:
	is_occupied = false
	placed_tile = null
