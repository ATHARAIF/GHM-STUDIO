extends Node

signal machine_registered(machine_id: String)
signal hopper_updated(hopper_id: String)

## Menyimpan daftar semua mesin yang sudah ditaruh di pabrik.
## Key: machine_id (String), Value: Dictionary berisi instance data
var placed_machines: Dictionary = {}

var factory_level: int = 1


func _ready() -> void:
	# Berikan 1 Starter Hopper gratis saat game dimulai
	var starter_data = preload("res://resources/items/machines/hopper_level_1.tres")
	register_machine("hopper_1", starter_data, Vector3(0, 0.05, 2))

## Saat kursor/player meletakkan mesin baru ke lantai pabrik
func register_machine(machine_id: String, item_data: ItemData, position: Vector3) -> void:
	if placed_machines.has(machine_id):
		return
		
	var machine_dict = {
		"id": machine_id,
		"data": item_data,
		"position": position,
		"current_batch": null, # Menyimpan clone dari CoffeeBatch
		"current_amount_kg": 0,
		"state": "IDLE",
		"wear_pct": 100.0
	}
	
	placed_machines[machine_id] = machine_dict
	machine_registered.emit(machine_id)

## Mengambil semua Hopper yang ada di pabrik
func get_all_hoppers() -> Array[Dictionary]:
	var hoppers: Array[Dictionary] = []
	for key in placed_machines:
		var m = placed_machines[key]
		if m["data"].category == ItemData.ItemCategory.HOPPER:
			hoppers.append(m)
	return hoppers

## Fungsi utama memecah batch dari kebun ke dalam Hopper (Click-to-fill)
## Mengembalikan jumlah kg yang berhasill masuk.
func fill_hopper(hopper_id: String, source_batch: CoffeeBatch, input_kg: int) -> int:
	if not placed_machines.has(hopper_id):
		return 0
		
	var hopper = placed_machines[hopper_id]
	var max_cap = hopper["data"].max_capacity
	
	# Jika hopper masih kosong, clone batch dari lahan!
	if hopper["current_batch"] == null:
		hopper["current_batch"] = source_batch.duplicate(true)
		hopper["current_amount_kg"] = 0
		
	var available_space = max_cap - hopper["current_amount_kg"]
	var amount_to_add = min(input_kg, available_space)
	
	hopper["current_amount_kg"] += amount_to_add
	hopper["current_batch"].cherry_kg = hopper["current_amount_kg"]
	
	hopper_updated.emit(hopper_id)
	return amount_to_add
