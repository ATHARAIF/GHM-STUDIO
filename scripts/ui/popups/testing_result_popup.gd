extends CanvasLayer

@onready var btn_close = $CenterContainer/panel/close
@onready var val_variety = $CenterContainer/panel/contents/VBoxContainer2/header/variety_name
@onready var val_species = $CenterContainer/panel/contents/VBoxContainer2/header/species_name

@onready var val_rating = $CenterContainer/panel/contents/VBoxContainer2/stats/VBoxContainer2/HBoxContainer/rating
@onready var val_speciality = $CenterContainer/panel/contents/VBoxContainer2/stats/VBoxContainer/speciality/value
@onready var val_size = $CenterContainer/panel/contents/VBoxContainer2/stats/VBoxContainer/size/value
@onready var val_stock = $CenterContainer/panel/contents/VBoxContainer2/stats/VBoxContainer/stock/value

@onready var radar_chart = $CenterContainer/panel/contents/VBoxContainer2/stats/VBoxContainer2/radar
@onready var val_note = $CenterContainer/panel/contents/VBoxContainer2/note/value

var target_batch = null
var current_tile: Node3D = null

func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(_on_close)
		
	# Tab switching
	var btn_info = $CenterContainer/panel/contents/VBoxContainer2/tab_button/info
	var btn_ideal = $CenterContainer/panel/contents/VBoxContainer2/tab_button/ideal
	var btn_terroir = $CenterContainer/panel/contents/VBoxContainer2/tab_button/terroir
	var btn_sales = $CenterContainer/panel/contents/VBoxContainer2/tab_button/sales
	
	var tab_group = ButtonGroup.new()
	if btn_info: btn_info.button_group = tab_group
	if btn_ideal: btn_ideal.button_group = tab_group
	if btn_terroir: btn_terroir.button_group = tab_group
	if btn_sales: btn_sales.button_group = tab_group
	
	if btn_info: btn_info.button_pressed = true
		
	hide()

func show_popup(tile_data: Dictionary) -> void:
	var batch_year = tile_data.get("target_batch_year")
	if batch_year != null and StageManager.batches.has(batch_year):
		target_batch = StageManager.batches[batch_year]
		
	current_tile = tile_data.get("tile")
	
	if target_batch:
		var display_custom_name = str(target_batch.variety_name)
		var display_species = str(target_batch.species_name) + " " + str(target_batch.variety_name)
		
		var score = 0.0
		var note_text = ""
		
		# Load the variety resource dynamically
		var variety_id = target_batch.variety_name.to_lower().replace(" ", "_")
		var variety_path = "res://resources/varieties/" + variety_id + ".tres"
		var variety_res = load(variety_path) if ResourceLoader.exists(variety_path) else null
		
		if variety_res != null:
			# 1. Target Ideal
			var dev_aci = abs(target_batch.acidity - variety_res.target_acidity)
			var dev_aro = abs(target_batch.aroma - variety_res.target_aroma)
			var dev_swe = abs(target_batch.sweetness - variety_res.target_sweetness)
			var dev_fla = abs(target_batch.flavor - variety_res.target_flavor)
			var dev_body = abs(target_batch.body - variety_res.target_body)
			var dev_bit = abs(target_batch.bitterness - variety_res.target_bitterness)
			
			# 2. Total Penalti = Sum(Deviasi * Bobot)
			var total_penalty = (dev_aci * variety_res.penalty_weight_acidity) + \
								(dev_aro * variety_res.penalty_weight_aroma) + \
								(dev_swe * variety_res.penalty_weight_sweetness) + \
								(dev_fla * variety_res.penalty_weight_flavor) + \
								(dev_body * variety_res.penalty_weight_body) + \
								(dev_bit * variety_res.penalty_weight_bitterness)
			
			# 3. Skor Dasar
			var skor_dasar = 80.0 * (1.0 - total_penalty)
			
			# 4. Bonus Notes
			var bonus_notes = 0.0
			var notes_arr = []
			
			if target_batch.variety_name == "Kintamani":
				if target_batch.acidity >= 8.0 and target_batch.aroma >= 8.0:
					bonus_notes += 5.0
					notes_arr.append("- Citrus & Bergamot Aroma Note")
					
				if target_batch.completed_processes.has("WP01"):
					bonus_notes += 5.0
					notes_arr.append("- Crisp Clean Aftertaste")
					
				if target_batch.has_meta("roast_level") and target_batch.get_meta("roast_level") == "Light":
					bonus_notes += 5.0
					notes_arr.append("- Floral & Brown Sugar Finish")
			
			score = skor_dasar + bonus_notes
			note_text = "\n".join(notes_arr)
			
		else:
			# Fallback untuk varietas lain
			var total_stats = target_batch.body + target_batch.acidity + target_batch.sweetness + target_batch.aroma + target_batch.flavor
			score = 50.0 + (total_stats * 1.5) - (target_batch.bitterness * 1.0)
			
		score = clamp(score, 0.0, 100.0)
		
		# Simpan kualitas ke batch
		target_batch.set_meta("quality_score", score)
		
		if val_rating:
			val_rating.text = str(round(score))
			
		if val_note and note_text != "":
			val_note.text = note_text
			
		if val_speciality:
			if score >= 90: val_speciality.text = "Outstanding"
			elif score >= 85: val_speciality.text = "Excellent"
			elif score >= 80: val_speciality.text = "Very Good"
			else: val_speciality.text = "Commercial"
			
		if val_stock or val_size:
			# Ambil data dari WarehouseManager karena stat fisik di CoffeeBatch (seperti roasted_bean_kg)
			# sudah disedot/dikonsumsi 100% oleh fase Packing (DP03).
			var total_qty = 0
			var pack_sizes = []
			
			if has_node("/root/WarehouseManager"):
				var wm = get_node("/root/WarehouseManager")
				var inv = wm.get_all_inventory()
				for item in inv:
					if item.has("batch_year") and item["batch_year"] == target_batch.batch_year:
						if item.has("custom_name") and item["custom_name"] != "":
							display_custom_name = item["custom_name"]
						total_qty += item["qty"]
						var p_size = str(item["packaging_size"]) + "g"
						if not pack_sizes.has(p_size):
							pack_sizes.append(p_size)
							
			if val_stock:
				val_stock.text = str(total_qty) + " Pcs"
			if val_size:
				val_size.text = ", ".join(pack_sizes) if pack_sizes.size() > 0 else "Unknown"
				
		if val_variety: val_variety.text = display_custom_name
		if val_species: val_species.text = display_species
			
		# Update Radar Chart
		if radar_chart and radar_chart.has_method("set_item_value"):
			radar_chart.set_item_value(0, target_batch.sweetness)
			radar_chart.set_item_value(1, target_batch.aroma)
			radar_chart.set_item_value(2, target_batch.acidity)
			radar_chart.set_item_value(3, target_batch.flavor)
			radar_chart.set_item_value(4, target_batch.bitterness)
			radar_chart.set_item_value(5, target_batch.body)
			
			if radar_chart.has_method("set_item_title"):
				var stats = [
					{"id": 0, "val": target_batch.sweetness, "target": variety_res.target_sweetness, "name": "Sweetness"},
					{"id": 1, "val": target_batch.aroma, "target": variety_res.target_aroma, "name": "Aroma"},
					{"id": 2, "val": target_batch.acidity, "target": variety_res.target_acidity, "name": "Acidity"},
					{"id": 3, "val": target_batch.flavor, "target": variety_res.target_flavor, "name": "Flavour"},
					{"id": 4, "val": target_batch.bitterness, "target": variety_res.target_bitterness, "name": "Bitterness"},
					{"id": 5, "val": target_batch.body, "target": variety_res.target_body, "name": "Body"}
				]
				for stat in stats:
					var dev = abs(stat.val - stat.target)
					if dev <= 0.01: # Harus pas persis 100% sama dengan target!
						radar_chart.set_item_title(stat.id, "★ " + stat.name + " ★")
					else:
						radar_chart.set_item_title(stat.id, stat.name)
			
			# Paksa render ulang radar chart
			if radar_chart.has_method("queue_redraw"):
				radar_chart.queue_redraw()
			
	show()

func _on_close() -> void:
	# Jika butuh logic setelah tutup popup, taruh di sini
	# Misal: resolve interaction
	var active_tiles = StageManager.active_tiles
	for i in range(active_tiles.size() - 1, -1, -1):
		var td = active_tiles[i]
		if td.tile == current_tile and td.data.process_id == "TEST01":
			StageManager.resolve_interaction(td, false)
			break
			
	queue_free()
