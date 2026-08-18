extends Node

## Autoload (Project Settings > Autoload, kasih nama "InventoryManager").
## Nyimpen item yang sudah dibeli: ItemData -> jumlah yang dimiliki.

signal inventory_changed

var owned_items: Dictionary = {}  # { ItemData: int quantity }

func add_item(item: ItemData, amount: int = 1) -> void:
	owned_items[item] = owned_items.get(item, 0) + amount
	inventory_changed.emit()

func get_quantity(item: ItemData) -> int:
	return owned_items.get(item, 0)

func remove_item(item: ItemData, amount: int = 1) -> void:
	if not owned_items.has(item):
		return
	owned_items[item] -= amount
	if owned_items[item] <= 0:
		owned_items.erase(item)
	inventory_changed.emit()

func get_owned_items() -> Array:
	return owned_items.keys()
