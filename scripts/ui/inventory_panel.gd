extends Control

## Attach ke root panel "Inventory" di dalam TabContainer.
## Struktur node sama seperti Shop:
## Inventory (Control, script ini)
## └── GridContainer (ItemGrid)

const ITEM_CARD_SCENE := preload("res://scenes/ui/item_card.tscn")  # sesuaikan path

@onready var item_grid: GridContainer = $ItemGrid

func _ready() -> void:
	WarehousePlacement.placement_changed.connect(_populate)
	_populate()

func _populate() -> void:
	for child in item_grid.get_children():
		child.queue_free()

	for item in WarehousePlacement.get_owned_items_in_building():
		var card := ITEM_CARD_SCENE.instantiate()
		item_grid.add_child(card)
		card.setup(item, "inventory")
