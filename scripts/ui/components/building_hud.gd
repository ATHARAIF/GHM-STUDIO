extends Control

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			accept_event()

@export var farm_scene_path: String = "res://scenes/maps/main_farm.tscn"
const ITEM_PANEL = preload("res://scenes/ui/components/building_item_panel.tscn")

@onready var btn_back = $footer/LeftBtn/MarginLeft/Left/BtnBack
@onready var btn_eye = $footer/LeftBtn/MarginLeft/Left/BtnEye
@onready var btn_inventory = $footer/RightBtn/MarginRight/Right/BtnInven
@onready var btn_shop = $footer/RightBtn/MarginRight/Right/BtnShop
@onready var btn_upgrade = $upgrade/MarginContainer/HBoxContainer/BtnContainer/Button

@onready var container_label = $footer/LabelItemContainer
@onready var container_list = $footer/ItemContainer
@onready var list_parent = $footer/ItemContainer/MarginItem/ItemContainer/ItemContainer

var is_showing_shop: bool = false

func _ready() -> void:
	if btn_back: btn_back.pressed.connect(_on_btn_back_pressed)
	if btn_eye: btn_eye.pressed.connect(_on_btn_eye_pressed)
	if btn_inventory: btn_inventory.pressed.connect(_on_btn_inventory_pressed)
	if btn_shop: btn_shop.pressed.connect(_on_btn_shop_pressed)
	if btn_upgrade: btn_upgrade.pressed.connect(_on_btn_upgrade_pressed)
	
	_clear_list()
	_update_level_label()
	_on_btn_inventory_pressed()

func _update_level_label() -> void:
	var value_label = $upgrade/MarginContainer/HBoxContainer/value
	if not value_label: return
	
	var scene = get_tree().current_scene
	if scene.name.find("Warehouse") != -1 or scene.name.find("warehouse") != -1:
		if scene.get("warehouse_level") != null:
			value_label.text = str(scene.warehouse_level)
	else:
		value_label.text = str(FactoryManager.factory_level)

func _on_btn_back_pressed() -> void:
	print("Keluar dari gedung, kembali ke ladang...")
	var scene = get_tree().current_scene
	if scene.name.find("Warehouse") != -1 or scene.name.find("warehouse") != -1:
		if StageManager.has_method("save_room_state"):
			StageManager.save_room_state("warehouse")
	else:
		if StageManager.has_method("save_room_state"):
			StageManager.save_room_state("prod_house")
			
	await TransitionManager.fade_out()
	get_tree().change_scene_to_file(farm_scene_path)
	TransitionManager.fade_in()

func _on_btn_eye_pressed() -> void:
	if container_label and container_list:
		var is_hidden = !container_list.visible
		container_list.visible = is_hidden
		container_label.visible = is_hidden

func _on_btn_inventory_pressed() -> void:
	is_showing_shop = false
	if container_label:
		var lbl = container_label.get_node_or_null("MarginContainer/LabelBox/Label")
		if lbl: lbl.text = "Inventory"
	_load_inventory()

func _on_btn_shop_pressed() -> void:
	is_showing_shop = true
	if container_label:
		var lbl = container_label.get_node_or_null("MarginContainer/LabelBox/Label")
		if lbl: lbl.text = "Shop"
	_load_shop()

func _on_btn_upgrade_pressed() -> void:
	print("Buka popup upgrade ruangan!")

func _clear_list() -> void:
	for child in list_parent.get_children():
		child.queue_free()

func _load_inventory() -> void:
	_clear_list()
	
	var is_warehouse = false
	var scene = get_tree().current_scene
	if scene.name.find("Warehouse") != -1 or scene.name.find("warehouse") != -1:
		is_warehouse = true
	
	var data_source = {}
	if is_warehouse:
		if has_node("/root/WarehouseManager"):
			data_source = get_node("/root/WarehouseManager").placed_racks
	else:
		data_source = FactoryManager.placed_machines
		
	for m_id in data_source:
		var m_data = data_source[m_id]
		var item: ItemData = m_data["data"]
		
		var panel_data = {
			"machine_id": m_id,
			"raw_item_data": item,
			"name": item.item_name,
			"desc": "Kapasitas: " + str(item.max_capacity),
			"buy_price": item.buy_price,
			"sell_price": item.sell_price,
			"specs": {
				"Max Capacity": str(item.max_capacity)
			},
			"wear_pct": m_data.get("wear_pct", 100.0),
			"state": m_data.get("state", "IDLE")
		}
		_create_item_card(panel_data, false)

func _load_shop() -> void:
	_clear_list()
	
	var available_items: Array[ItemData] = []
	var scene = get_tree().current_scene
	
	if scene.name.find("Warehouse") != -1 or scene.name.find("warehouse") != -1:
		if ResourceLoader.exists("res://resources/items/machines/wooden_pallet.tres"):
			available_items.append(load("res://resources/items/machines/wooden_pallet.tres"))
	else:
		available_items.append(preload("res://resources/items/machines/hopper_level_1.tres"))
		available_items.append(preload("res://resources/items/machines/patio_level_1.tres"))
		available_items.append(preload("res://resources/items/machines/roaster_level_1.tres"))
	
	for item in available_items:
		var panel_data = {
			"raw_item_data": item,
			"name": item.item_name,
			"desc": "Kapasitas: " + str(item.max_capacity),
			"buy_price": item.buy_price,
			"sell_price": item.sell_price,
			"specs": {
				"Max Capacity": str(item.max_capacity)
			}
		}
		_create_item_card(panel_data, true)

func _create_item_card(data: Dictionary, is_shop: bool) -> void:
	# Instansiasi komponen panel yang sudah dipisah!
	var new_item = ITEM_PANEL.instantiate()
	list_parent.add_child(new_item)
	
	# Gunakan fungsi setup_panel dari building_item_panel.gd
	var mode = "shop" if is_shop else "inventory"
	if new_item.has_method("setup_panel"):
		new_item.setup_panel(data, mode)
