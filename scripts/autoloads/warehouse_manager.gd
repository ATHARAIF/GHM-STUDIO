extends Node

signal inventory_updated

var inventory: Array[Dictionary] = []

## Menyimpan daftar semua rak/pallet yang ditaruh di warehouse
## Key: rack_id (String), Value: Dictionary berisi instance data
var placed_racks: Dictionary = {}

func _ready() -> void:
	# Berikan 1 Wooden Pallet gratis saat game dimulai!
	var pallet_data = load("res://resources/items/machines/wooden_pallet.tres")
	if pallet_data:
		# Posisi sementara, nanti otomatis digeser ke grid kosong oleh _spawn_warehouse_racks
		register_rack("default_pallet_1", pallet_data, Vector3(-1, 0, -1), 0)

func register_rack(rack_id: String, item_data: Resource, position: Vector3, rotation_steps: int = 0) -> void:
	if placed_racks.has(rack_id):
		return
		
	var rack_dict = {
		"id": rack_id,
		"data": item_data,
		"position": position,
		"rotation_steps": rotation_steps,
		"current_amount": 0,
		"stored_items": [] # Array of inventory items
	}
	
	placed_racks[rack_id] = rack_dict
	print("[Warehouse] Registered rack: ", rack_id)

func update_rack_transform(rack_id: String, new_pos: Vector3, rot_steps: int) -> void:
	if placed_racks.has(rack_id):
		placed_racks[rack_id]["position"] = new_pos
		placed_racks[rack_id]["rotation_steps"] = rot_steps

func store_packed_goods(batch: CoffeeBatch, packaging_data: Dictionary) -> void:
	# packaging_data contains: packs, size, type, material
	var new_item = {
		"batch_year": batch.batch_year,
		"species": batch.species_name,
		"variety": batch.variety_name,
		
		# Kualitas rasa dan atribut lainnya dibawa ke gudang!
		"aroma": batch.aroma,
		"acidity": batch.acidity,
		"body": batch.body,
		"sweetness": batch.sweetness,
		"flavor": batch.flavor,
		"bitterness": batch.bitterness,
		"defect_rate": batch.defect_rate,
		
		"packaging_size": packaging_data["size"],
		"packaging_type": packaging_data["type"],
		"packaging_material": packaging_data["material"],
		"qty": packaging_data["packs"]
	}
	
	# Coba ditumpuk (stack) jika ada barang yang speknya 100% sama persis
	var found = false
	for item in inventory:
		if _is_same_specs(item, new_item):
			item["qty"] += new_item["qty"]
			found = true
			break
			
	if not found:
		inventory.append(new_item)
		
	inventory_updated.emit()
	print("[Warehouse] Stored ", new_item["qty"], " packs of ", new_item["variety"], " ", new_item["packaging_size"], "g")

func _is_same_specs(item_a: Dictionary, item_b: Dictionary) -> bool:
	# Kita cek kesamaan dari tahun, jenis, packaging, sampai kualitas rasa
	var keys_to_check = [
		"batch_year", "species", "variety", "packaging_size", "packaging_type", "packaging_material",
		"aroma", "acidity", "body", "sweetness", "flavor", "bitterness", "defect_rate"
	]
	
	for key in keys_to_check:
		if item_a[key] != item_b[key]:
			return false
	return true

func get_all_inventory() -> Array[Dictionary]:
	return inventory
