extends CanvasLayer
@onready var tab_container = $TabContainer

#result panel
@onready var lbl_result = $TabContainer/result/panel/panel_label
@onready var lbl_quality = $TabContainer/result/panel/content/bean_detail/left/bean_data/quality/value
@onready var lbl_yield = $TabContainer/result/panel/content/bean_detail/left/bean_data/yield/value
@onready var btn_manage = $TabContainer/result/panel/content/confirmation/confirm

#storage_selection
@onready var lbl_str_select = $TabContainer/storage_selection/panel/panel_label
@onready var batch_variety = $TabContainer/storage_selection/panel/content/left/variety_batch
@onready var lbl_qty = $TabContainer/storage_selection/panel/content/left/data/quantity/value
@onready var lbl_qty_stored = $TabContainer/storage_selection/panel/content/left/data/quantity_stored/value
@onready var lbl_qty_sell = $TabContainer/storage_selection/panel/content/left/data/quantity_sell/value
@onready var lbl_selling_price = $TabContainer/storage_selection/panel/content/left/data/selling_price/value
@onready var lbl_income = $TabContainer/storage_selection/panel/content/left/data/income/value
#storage_selection - storage list
@onready var illustration = $TabContainer/storage_selection/panel/content/right/list/VBoxContainer/storage/HBoxContainer/illustration

# --- STORAGE SELECTION (LIST & BUTTONS) ---
@onready var storage_list_container = $TabContainer/storage_selection/panel/content/right/list/VBoxContainer
@onready var storage_template = $TabContainer/storage_selection/panel/content/right/list/VBoxContainer/storage

@onready var btn_back = $TabContainer/storage_selection/panel/content/left/back
@onready var btn_confirm = $TabContainer/storage_selection/panel/content/right/confirmation/confirm

var current_tile_data: Dictionary
var total_harvest_kg: int = 0
var remaining_harvest_kg: int = 0
var stored_harvest_kg: int = 0
var selected_hoppers: Array[String] = []

func _ready() -> void:
	UIUtils.setup_input_blocker(self)
	
	tab_container.current_tab = 0
	btn_manage.text = "MANAGE HARVEST"
	
	btn_manage.pressed.connect(_go_to_storage_selection)
	btn_back.pressed.connect(_go_to_result_panel)
	btn_confirm.pressed.connect(_finalize_harvest)
	
	# Sembunyikan template asli dari UI
	storage_template.hide()

func show_popup(tile_data: Dictionary) -> void:
	current_tile_data = tile_data
	var cb = StageManager.get_active_farm_batch()
		
	# Penentuan Kualitas
	var q_text = "Good"
	var q_color = Color(0.2, 0.8, 0.2)
	if cb.defect_rate > 30:
		q_text = "Poor"
		q_color = Color(0.8, 0.2, 0.2)
	elif cb.defect_rate > 15:
		q_text = "Fair"
		q_color = Color(0.8, 0.6, 0.2)
		
	lbl_quality.text = q_text
	lbl_quality.modulate = q_color
	
	# Kalkulasi Kuantitas
	var preview_yield = 0
	var em = Engine.get_main_loop().root.get_node_or_null("StageManager")
	if em and em.current_location and em.current_location.current_tree:
		var raw = em.current_location.current_tree.calculate_harvest_yield()
		var card_effect = 1.0
		if tile_data.has("data") and tile_data["data"] != null:
			card_effect = 1.0 + tile_data["data"].base_mod_yield
		if tile_data.has("mod_quant_pct"):
			card_effect *= (1.0 + float(tile_data["mod_quant_pct"]))
		preview_yield = int(clamp(raw * cb.accumulated_yield_modifier * card_effect, 0, 10000))
		
	total_harvest_kg = preview_yield
	lbl_yield.text = "%d Kg" % preview_yield
	
	show()

func _go_to_result_panel() -> void:
	# Reset pilihan jika user kembali ke step 1
	selected_hoppers.clear()
	tab_container.current_tab = 0

func _go_to_storage_selection() -> void:
	tab_container.current_tab = 1
	_refresh_storage_ui()

func _refresh_storage_ui() -> void:
	# 1. Bersihkan list (kecuali template)
	for child in storage_list_container.get_children():
		if child != storage_template:
			child.queue_free()
			
	# 2. Kalkulasi Ulang Variabel Dinamis
	stored_harvest_kg = 0
	var fm = null
	if Engine.get_main_loop().root.has_node("FactoryManager"):
		fm = Engine.get_main_loop().root.get_node("FactoryManager")
		
	if fm:
		for h_id in selected_hoppers:
			for h in fm.get_all_hoppers():
				if h["id"] == h_id:
					var space = h["data"].max_capacity - h["current_amount_kg"]
					stored_harvest_kg += min(total_harvest_kg - stored_harvest_kg, space)
	
	remaining_harvest_kg = total_harvest_kg - stored_harvest_kg
	var sell_price_per_kg = 5
	
	# 3. Update Teks di Panel Kiri (Stats)
	var cb = StageManager.get_active_farm_batch()
	
	var var_name = "Coffee"
	var em = Engine.get_main_loop().root.get_node_or_null("StageManager")
	if em and em.current_location and em.current_location.variety_data:
		var_name = em.current_location.variety_data.variety_name
		
	batch_variety.text = "%s %d" % [var_name, cb.batch_year]
	lbl_qty.text = "%d Kg" % total_harvest_kg
	lbl_qty_stored.text = "%d Kg" % stored_harvest_kg
	lbl_qty_sell.text = "%d Kg" % remaining_harvest_kg
	lbl_selling_price.text = "$ %d / Kg" % sell_price_per_kg
	lbl_income.text = "$ %d" % (remaining_harvest_kg * sell_price_per_kg)
	
	# 4. Update Teks Tombol Confirm (English)
	if remaining_harvest_kg == total_harvest_kg:
		btn_confirm.text = "SELL ALL"
	elif remaining_harvest_kg == 0:
		btn_confirm.text = "STORE ALL"
	else:
		btn_confirm.text = "ASSIGN & SELL"
		
	# 5. Bangun Ulang Daftar Hopper di Kanan
	if fm:
		var hoppers = fm.get_all_hoppers()
		
		if hoppers.size() == 0:
			var lbl_empty = Label.new()
			lbl_empty.text = "No Storage Tanks available!\nAll harvest will be sold automatically."
			lbl_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_empty.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
			storage_list_container.add_child(lbl_empty)
			
		for h in hoppers:
			var h_id = h["id"]
			var cap = h["data"].max_capacity
			var cur = h["current_amount_kg"]
			var space = cap - cur
			
			# Duplikat template
			var item = storage_template.duplicate()
			item.show()
			storage_list_container.add_child(item)
			
			# Akses node di dalam item duplikat
			var t_name = item.get_node("HBoxContainer/MarginContainer/VBoxContainer/name")
			var t_cap = item.get_node("HBoxContainer/MarginContainer/VBoxContainer/capacity")
			var t_avail = item.get_node("HBoxContainer/MarginContainer/VBoxContainer/available")
			var t_check = item.get_node("HBoxContainer/checbox/CheckBox")
			
			t_name.text = h["data"].item_name
			t_cap.text = "Capacity: %d Kg" % cap
			
			if selected_hoppers.has(h_id):
				t_check.button_pressed = true
				var filled = min(total_harvest_kg, space) # Perkiraan kasar
				t_avail.text = "Will be filled"
			else:
				t_check.button_pressed = false
				t_avail.text = "Available: %d Kg" % space
				# Disable checkbox jika panen sudah habis dialokasikan, dan hopper ini belum terpilih
				if remaining_harvest_kg <= 0 or space <= 0:
					t_check.disabled = true
			
			# Event Click pada Checkbox
			t_check.toggled.connect(func(is_pressed: bool):
				if is_pressed:
					if not selected_hoppers.has(h_id):
						selected_hoppers.append(h_id)
				else:
					if selected_hoppers.has(h_id):
						selected_hoppers.erase(h_id)
				
				# Panggil ulang UI untuk memperbarui angka
				_refresh_storage_ui()
			)

func _finalize_harvest() -> void:
	var fm = null
	if Engine.get_main_loop().root.has_node("FactoryManager"):
		fm = Engine.get_main_loop().root.get_node("FactoryManager")
		
	if fm:
		var cb = StageManager.get_active_farm_batch()
		var virtual_remaining = total_harvest_kg
		
		# Proses yang disedot ke hopper
		for h_id in selected_hoppers:
			for h in fm.get_all_hoppers():
				if h["id"] == h_id:
					var space = h["data"].max_capacity - h["current_amount_kg"]
					var amount = min(virtual_remaining, space)
					fm.fill_hopper(h_id, cb, amount)
					virtual_remaining -= amount
					break
		
		# Jual sisanya
		var final_sell = virtual_remaining
		if final_sell > 0:
			StageManager.budget += (final_sell * 5)
			StageManager.budget_changed.emit(StageManager.budget)
			
		# Jika tidak ada kopi sama sekali yang masuk pabrik (100% dijual)
		if final_sell == total_harvest_kg:
			cb.set_meta("sold_out", true)
			
	StageManager.resolve_interaction(current_tile_data, true)
	queue_free()
