extends PanelContainer

# Ref Ilustrasi gambar Item
@onready var illustration = $VBoxContainer/Illustrasi

# Item Name
@onready var item_name = $VBoxContainer/Content/VBoxContainer/ItemName/ItemName

# Referensi Custom Button Tab (Sesuaikan namanya dengan yang Anda buat)
@onready var btn_tab_buy = $VBoxContainer/Content/VBoxContainer/BtnTab/BtnBuy
@onready var btn_tab_status = $VBoxContainer/Content/VBoxContainer/BtnTab/BtnStatus
@onready var btn_tab_info = $VBoxContainer/Content/VBoxContainer/BtnTab/BtnInfo
@onready var btn_tab_data = $VBoxContainer/Content/VBoxContainer/BtnTab/BtnData
@onready var btn_tab_sell = $VBoxContainer/Content/VBoxContainer/BtnTab/BtnSell

# Referensi Tab Container
@onready var tab_container = $VBoxContainer/Content/VBoxContainer/ValueTabContainer

# Referensi Konten Data
# Value BuyTab
@onready var buy_price = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/BuyTab/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/Value
@onready var btn_action_buy = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/BuyTab/MarginContainer/VBoxContainer/BtnBuy
# Value StatusTab
@onready var wear_status = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/StatusTab/MarginContainer/VBoxContainer/VBoxContainer/ProgressBar
@onready var cleaning_btn = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/StatusTab/MarginContainer/VBoxContainer/BtnStatus
# value InfoTab
@onready var lbl_desc = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/InfoTab/MarginContainer/VBoxContainer/Scroll/Desc
# value DataTab
@onready var data_name = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/DataTab/MarginContainer/ScrollContainer/VBoxContainer/Data/Label
@onready var data_value = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/DataTab/MarginContainer/ScrollContainer/VBoxContainer/Data/value
# value SellTab
@onready var sell_price = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/SellTab/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/Value
@onready var btn_action_sell = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/SellTab/MarginContainer/VBoxContainer/BtnSell

var current_data: Dictionary
func _ready() -> void:
	# 1. Pastikan tab bawaan Godot mati
	tab_container.tabs_visible = false
	
	# Mulai mendeteksi hover via process
	set_process(true)
	
	# 2. Hubungkan Custom Button ke TabContainer
	# Urutan indeks (0-4) bergantung pada urutan Tab di dalam ValueTabContainer di Scene Tree Anda.
	# Asumsi urutannya: BuyTab(0), StatusTab(1), InfoTab(2), DataTab(3), SellTab(4)
	if btn_tab_buy:
		btn_tab_buy.pressed.connect(func(): tab_container.current_tab = tab_container.get_node("BuyTab").get_index())
	if btn_tab_status:
		btn_tab_status.pressed.connect(func(): tab_container.current_tab = tab_container.get_node("StatusTab").get_index())
	if btn_tab_info:
		btn_tab_info.pressed.connect(func(): tab_container.current_tab = tab_container.get_node("InfoTab").get_index())
	if btn_tab_data:
		btn_tab_data.pressed.connect(func(): tab_container.current_tab = tab_container.get_node("DataTab").get_index())
	if btn_tab_sell:
		btn_tab_sell.pressed.connect(func(): tab_container.current_tab = tab_container.get_node("SellTab").get_index())

var is_hovering: bool = false

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		if is_hovering:
			is_hovering = false
			_set_machine_highlight(false)
		return
		
	var mouse_pos = get_global_mouse_position()
	var rect = get_global_rect()
	var now_hovering = rect.has_point(mouse_pos)
	
	if now_hovering != is_hovering:
		is_hovering = now_hovering
		_set_machine_highlight(is_hovering)

func _set_machine_highlight(enable: bool) -> void:
	if current_data.has("machine_id"):
		var m_id = current_data["machine_id"]
		if FactoryManager.placed_machines.has(m_id):
			var node = FactoryManager.placed_machines[m_id].get("node")
			if is_instance_valid(node):
				SilhouetteHighlight.apply_highlight(node, enable)

# Fungsi ini dipanggil dari building_hud.gd saat memunculkan panel
func setup_panel(data: Dictionary, mode: String) -> void:
	current_data = data
	
	# Isi data teks dasar
	if item_name: item_name.text = data.get("name", "Unknown Item")
	if lbl_desc: lbl_desc.text = data.get("desc", "Tanpa deskripsi")
	if buy_price: buy_price.text = str(data.get("buy_price", 0))
	if sell_price: sell_price.text = str(data.get("sell_price", 0))
	
	# Populate specs (Data Tab)
	if data_name and data_value and data.has("specs"):
		var spec_dict = data["specs"]
		var keys_str = ""
		var vals_str = ""
		for key in spec_dict.keys():
			keys_str += str(key) + "\n"
			vals_str += str(spec_dict[key]) + "\n"
		data_name.text = keys_str.strip_edges()
		data_value.text = vals_str.strip_edges()
	else:
		if data_name: data_name.text = "No Data"
		if data_value: data_value.text = "-"
	
	# Reset tombol (Tampilkan semua dulu)
	if btn_tab_buy: btn_tab_buy.show()
	if btn_tab_status: btn_tab_status.show()
	if btn_tab_info: btn_tab_info.show()
	if btn_tab_data: btn_tab_data.show()
	if btn_tab_sell: btn_tab_sell.show()
	
	if mode == "shop":
		# Di Shop: Pemain hanya bisa melihat Info, Data, dan Buy. (Sembunyikan Status & Sell)
		if btn_tab_status: btn_tab_status.hide()
		if btn_tab_sell: btn_tab_sell.hide()
		
		# Arahkan tab awal ke Buy
		if tab_container.has_node("BuyTab"):
			tab_container.current_tab = tab_container.get_node("BuyTab").get_index()
		
		if btn_action_buy:
			# Gunakan bind untuk passing data
			# Kita aman dari koneksi ganda karena panel ini selalu dibuat baru (instantiate)
			btn_action_buy.pressed.connect(_buy_item.bind(data))
		
	elif mode == "inventory":
		# Di Inventory: Pemain tidak bisa "Buy" lagi
		if btn_tab_buy: btn_tab_buy.hide()
		
		# Update wear dan button state
		if data.has("wear_pct") and wear_status:
			wear_status.value = data["wear_pct"]
			
		if cleaning_btn:
			var state = data.get("state", "IDLE")
			if state == "USED":
				cleaning_btn.text = "In Use"
				cleaning_btn.disabled = true
			elif data.get("wear_pct", 100) < 50:
				cleaning_btn.text = "Cleaning"
				cleaning_btn.disabled = false
			else:
				cleaning_btn.text = "Idle"
				cleaning_btn.disabled = true
		
		# Arahkan tab awal ke Info atau Status
		if tab_container.has_node("StatusTab"):
			tab_container.current_tab = tab_container.get_node("StatusTab").get_index()
		
		if btn_action_sell:
			btn_action_sell.pressed.connect(_sell_item.bind(data))

func _buy_item(data: Dictionary) -> void:
	if not data.has("raw_item_data"):
		print("Data mesin tidak valid untuk dibeli!")
		return
		
	var item: ItemData = data["raw_item_data"]
	
	var spot_data = PlacementManager.find_empty_grid_spot(item)
	if spot_data.is_empty():
		print("Pembelian dibatalkan: Ruangan sudah penuh atau ukuran tidak pas!")
		return
		
	var empty_anchor = spot_data["tile"]
	var rotation_steps = spot_data["rotation_steps"]
		
	if StageManager.budget >= item.buy_price:
		StageManager.budget -= item.buy_price
		StageManager.budget_changed.emit(StageManager.budget)
		
		# Letakkan di grid kosong secara otomatis
		var unique_id = item.item_name.to_lower().replace(" ", "_") + "_" + str(Time.get_ticks_msec())
		
		# Tumbuhkan mesin 3D di ruangan
		var tile = item.tile_scene.instantiate()
		get_tree().current_scene.add_child(tile)
		
		# Terapkan rotasi
		tile.rotation_degrees.y = float(rotation_steps) * 90.0
		
		var final_pos = empty_anchor.global_position
		final_pos.y += PlacementManager.ground_top_offset - PlacementManager._get_bottom_y(tile)
		tile.global_position = final_pos
		
		PlacementManager.reoccupy_grid_for_restored_tile(tile, item)
		
		var scene = get_tree().current_scene
		if scene.name.find("Warehouse") != -1 or scene.name.find("warehouse") != -1:
			var wm = get_node("/root/WarehouseManager")
			if wm:
				wm.register_rack(unique_id, item, tile.global_position, rotation_steps)
				wm.placed_racks[unique_id]["node"] = tile
		else:
			FactoryManager.register_machine(unique_id, item, tile.global_position)
			FactoryManager.placed_machines[unique_id]["node"] = tile
			FactoryManager.placed_machines[unique_id]["rotation_steps"] = rotation_steps
		
		print("Berhasil membeli dan langsung meletakkan: ", item.item_name)
	else:
		print("Uang tidak cukup untuk membeli ", item.item_name)

func _sell_item(data: Dictionary) -> void:
	if not data.has("raw_item_data"):
		return
		
	var item: ItemData = data["raw_item_data"]
	
	# Jual barang yang sudah di lantai (punya machine_id)
	if data.has("machine_id"):
		var m_id = data["machine_id"]
		
		var scene = get_tree().current_scene
		var is_warehouse = scene.name.find("Warehouse") != -1 or scene.name.find("warehouse") != -1
		
		var data_source = null
		if is_warehouse:
			var wm = get_node_or_null("/root/WarehouseManager")
			if wm: data_source = wm.placed_racks
		else:
			data_source = FactoryManager.placed_machines
			
		if data_source and data_source.has(m_id):
			var m_data = data_source[m_id]
			var node = m_data.get("node")
			if is_instance_valid(node):
				PlacementManager.remove_tile_from_grid(node)
				node.queue_free()
			
			data_source.erase(m_id)
			StageManager.budget += item.sell_price
			StageManager.budget_changed.emit(StageManager.budget)
			print("Berhasil menjual item yang terpasang: ", item.item_name)
			queue_free()
			return

func _on_place_item(data: Dictionary) -> void:
	# Jika nanti ada tombol Place khusus
	print("Memasang: ", data.get("name"))
