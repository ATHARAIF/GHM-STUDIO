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
@onready var cleaning_btn = $VBoxContainer/Content/VBoxContainer/ValueTabContainer/StatusTab/MarginContainer/VBoxContainer/BtnCleaning
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
		
		# Arahkan tab awal ke Info atau Buy
		if tab_container.has_node("InfoTab"):
			tab_container.current_tab = tab_container.get_node("InfoTab").get_index()
		
		if btn_action_buy:
			# Hindari koneksi ganda jika panel digunakan ulang
			if btn_action_buy.pressed.is_connected(_buy_item):
				btn_action_buy.pressed.disconnect(_buy_item)
			# Gunakan bind untuk passing data
			btn_action_buy.pressed.connect(_buy_item.bind(data))
		
	elif mode == "inventory":
		# Di Inventory: Pemain tidak bisa "Buy" lagi
		if btn_tab_buy: btn_tab_buy.hide()
		
		# Arahkan tab awal ke Info atau Status
		if tab_container.has_node("StatusTab"):
			tab_container.current_tab = tab_container.get_node("StatusTab").get_index()
		
		if btn_action_sell:
			if btn_action_sell.pressed.is_connected(_sell_item):
				btn_action_sell.pressed.disconnect(_sell_item)
			btn_action_sell.pressed.connect(_sell_item.bind(data))

func _buy_item(data: Dictionary) -> void:
	print("Membeli: ", data.get("name"))

func _sell_item(data: Dictionary) -> void:
	print("Menjual: ", data.get("name"))

func _on_place_item(data: Dictionary) -> void:
	# Jika nanti ada tombol Place khusus
	print("Memasang: ", data.get("name"))
