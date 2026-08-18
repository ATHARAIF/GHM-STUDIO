extends Control

## Attach ke root panel "Shop" di dalam TabContainer.
## Struktur node:
## Shop (Control, script ini)
## └── GridContainer (ItemGrid)   # atur "Columns" di Inspector, misal 3

const ITEM_CARD_SCENE := preload("res://scenes/ui/item_card.tscn")  # sesuaikan path

@export var available_items: Array[ItemData] = []  # isi lewat Inspector

@onready var item_grid: GridContainer = $ItemGrid

func _ready() -> void:
	_populate()

func _populate() -> void:
	for child in item_grid.get_children():
		child.queue_free()

	for item in available_items:
		var card := ITEM_CARD_SCENE.instantiate()
		item_grid.add_child(card)
		card.setup(item, "shop")
