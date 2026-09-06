extends Control

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
	
	# Hapus node dummy bawaan editor sebelum memuat data asli
	_clear_list()
		
	# Default buka inventory (Panggil simulasi klik tombol agar judul label ikut berubah)
	_on_btn_inventory_pressed()

func _on_btn_back_pressed() -> void:
	print("Keluar dari pabrik, kembali ke ladang...")
	if StageManager.has_method("save_room_state"):
		StageManager.save_room_state("prod_house")
		
	await TransitionManager.fade_out()
	get_tree().change_scene_to_file(farm_scene_path)
	TransitionManager.fade_in()

func _on_btn_eye_pressed() -> void:
	# Toggle hide/unhide
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
	# Hapus semua anak di kontainer (termasuk dummy dari editor)
	for child in list_parent.get_children():
		child.queue_free()

func _load_inventory() -> void:
	_clear_list()
	var dummy_inventory = [
		{"name": "Roaster Level 1", "desc": "Mesin sangrai kopi dasar.", "sell_price": 50},
		{"name": "Grinder Manual", "desc": "Penggiling kopi tradisional.", "sell_price": 10}
	]
	
	for data in dummy_inventory:
		_create_item_card(data, false)

func _load_shop() -> void:
	_clear_list()
	var dummy_shop = [
		{"name": "Roaster Level 2", "desc": "Mesin sangrai industri kapasitas besar.", "buy_price": 500},
		{"name": "Espresso Machine", "desc": "Ekstrak kopi super cepat.", "buy_price": 1000},
		{"name": "Fermentation Tank", "desc": "Tangki fermentasi ceri kopi.", "buy_price": 300}
	]
	
	for data in dummy_shop:
		_create_item_card(data, true)

func _create_item_card(data: Dictionary, is_shop: bool) -> void:
	# Instansiasi komponen panel yang sudah dipisah!
	var new_item = ITEM_PANEL.instantiate()
	list_parent.add_child(new_item)
	
	# Gunakan fungsi setup_panel dari building_item_panel.gd
	var mode = "shop" if is_shop else "inventory"
	if new_item.has_method("setup_panel"):
		new_item.setup_panel(data, mode)
