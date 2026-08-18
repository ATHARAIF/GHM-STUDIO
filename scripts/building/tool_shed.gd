extends Node3D

func _ready() -> void:
	WarehousePlacement.set_building_id("tool_shed")
	WarehousePlacement.register_camera($Camera3D)
	WarehousePlacement.register_items_container($PlacedItems)
	WarehousePlacement.register_floor($tile_grounds)
	WarehousePlacement.rebuild_placed_items()
