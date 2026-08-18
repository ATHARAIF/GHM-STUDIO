extends PanelContainer

## Attach ke root node "ItemCard". Struktur node yang perlu kamu susun
## di editor (semua di bawah root PanelContainer ini):
##
## ItemCard (PanelContainer)
## └── VBoxContainer
##     ├── Icon (TextureRect)
##     ├── NameLabel (Label)
##     ├── PriceOrQtyLabel (Label)
##     └── ActionButton (Button)   # teks "BUY" di shop, "SELL" di inventory

@onready var icon: TextureRect = $VBoxContainer/Icon
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var info_label: Label = $VBoxContainer/PriceOrQtyLabel
@onready var action_button: Button = $VBoxContainer/ActionButton

var item: ItemData
var mode: String = "shop"  # "shop" atau "inventory"

func setup(p_item: ItemData, p_mode: String) -> void:
	item = p_item
	mode = p_mode
	icon.texture = item.icon
	name_label.text = item.item_name

	if mode == "shop":
		info_label.text = "Price\n%d €" % item.price
		action_button.text = "BUY"
	else:
		info_label.text = "Owned: %d" % WarehousePlacement.get_owned_count_in_building(item)
		action_button.text = "SELL"

	action_button.pressed.connect(_on_action_pressed)

func _on_action_pressed() -> void:
	if mode == "shop":
		_try_buy()
	else:
		_try_sell()

func _try_buy() -> void:
	if not StageManager.spend(item.price):
		return  # TODO: tampilin feedback "budget kurang" kalau mau

	var placed := WarehousePlacement.spawn_item(item)
	if placed == null:
		StageManager.add(item.price)  # refund, gagal ditaro (lantai penuh)
		return  # TODO: tampilin feedback "lahan penuh" kalau mau

	InventoryManager.add_item(item, 1)

func _try_sell() -> void:
	if WarehousePlacement.get_owned_count_in_building(item) <= 0:
		return
	if not WarehousePlacement.remove_one(item):
		return
	InventoryManager.remove_item(item, 1)
	StageManager.add(item.price / 2)  # jual balik setengah harga, sesuaikan kalau mau beda
	info_label.text = "Owned: %d" % WarehousePlacement.get_owned_count_in_building(item)
