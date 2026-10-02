extends Control

@onready var list_container = $contents/bean_list/list/VBoxContainer
@onready var btn_template = $contents/bean_list/list/VBoxContainer/bean

@onready var right_panel = $contents/VBoxContainer2
@onready var val_variety = $contents/VBoxContainer2/header/variety_name
@onready var val_species = $contents/VBoxContainer2/header/species_name
@onready var radar_chart = $contents/VBoxContainer2/stats/VBoxContainer2/radar
@onready var val_star = $contents/VBoxContainer2/stats/VBoxContainer2/HBoxContainer/star
@onready var val_rating = $contents/VBoxContainer2/stats/VBoxContainer2/HBoxContainer/rating
@onready var val_speciality = $contents/VBoxContainer2/stats/VBoxContainer/speciality/value
@onready var val_note = $contents/VBoxContainer2/note/value
@onready var subviewport_container = $contents/VBoxContainer2/stats/PanelContainer/Control/SubViewportContainer

var inventory_items: Array[Dictionary] = []
var empty_label: Label = null

func _ready() -> void:
	if btn_template:
		btn_template.hide()
		
	empty_label = Label.new()
	empty_label.text = "No Coffee Available"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", 20)
	empty_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	empty_label.hide()
	list_container.add_child(empty_label)
	
	if has_node("/root/WarehouseManager"):
		var wm = get_node("/root/WarehouseManager")
		if wm.has_signal("inventory_updated"):
			wm.inventory_updated.connect(_refresh_list)
			
	visibility_changed.connect(_on_visibility_changed)
	_refresh_list()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_list()

func _refresh_list() -> void:
	for child in list_container.get_children():
		if child != btn_template and child != empty_label:
			child.queue_free()
			
	if not has_node("/root/WarehouseManager"): return
	
	var wm = get_node("/root/WarehouseManager")
	inventory_items = wm.get_all_inventory()
	
	var first_btn = null
	for i in range(inventory_items.size()):
		var item = inventory_items[i]
		var btn = btn_template.duplicate()
		btn.show()
		
		var custom_name = str(item.get("custom_name", item.get("variety", "Unknown")))
		var year = str(item.get("batch_year", ""))
		var size = str(item.get("packaging_size", 0)) + "g"
		var qty = str(item.get("qty", 0))
		
		# Tampilkan skor atau tanda tanya kalau belum ditest (Cupping)
		var quality = float(item.get("quality_score", -1.0))
		var score_text = "-"
		if quality >= 0.0:
			score_text = str(round(quality))
		
		var lbl_custom = btn.get_node_or_null("HBoxContainer/name/custom_name")
		if lbl_custom: lbl_custom.text = custom_name
		
		var lbl_year = btn.get_node_or_null("HBoxContainer/name/year batch")
		if lbl_year: lbl_year.text = year
			
		var lbl_rating = btn.get_node_or_null("HBoxContainer/HBoxContainer2/rating")
		if lbl_rating: lbl_rating.text = score_text
			
		var lbl_size = btn.get_node_or_null("HBoxContainer/size")
		if lbl_size: lbl_size.text = size
			
		var lbl_stock_avail = btn.get_node_or_null("HBoxContainer/HBoxContainer/stock_avail")
		if lbl_stock_avail: lbl_stock_avail.text = qty
			
		var lbl_stock_packed = btn.get_node_or_null("HBoxContainer/HBoxContainer/stock_packed")
		if lbl_stock_packed: lbl_stock_packed.text = qty
		
		btn.text = "" 
		btn.pressed.connect(_on_item_selected.bind(i))
		list_container.add_child(btn)
		
		if first_btn == null:
			first_btn = btn
			
	if first_btn:
		empty_label.hide()
		first_btn.button_pressed = true
		_on_item_selected(0)
	else:
		empty_label.show()
		_clear_details()

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= inventory_items.size(): return
	var item = inventory_items[index]
	
	if right_panel:
		var tween = create_tween()
		tween.tween_property(right_panel, "modulate:a", 1.0, 0.2)
	
	print("[DEBUG] Item: ", item)
	var variety = str(item.get("variety", "Unknown"))
	var custom_name = str(item.get("custom_name", variety))
	
	val_variety.text = custom_name
	val_species.text = (str(item.get("species", "")) + " " + variety).strip_edges()
	
	# Update Radar Chart dengan metode set_item_value bawaan UI radar kamu
	if radar_chart and radar_chart.has_method("set_item_value"):
		radar_chart.set_item_value(0, item.get("sweetness", 0.0))
		radar_chart.set_item_value(1, item.get("aroma", 0.0))
		radar_chart.set_item_value(2, item.get("acidity", 0.0))
		radar_chart.set_item_value(3, item.get("flavor", 0.0))
		radar_chart.set_item_value(4, item.get("bitterness", 0.0))
		radar_chart.set_item_value(5, item.get("body", 0.0))
		
		if radar_chart.has_method("queue_redraw"):
			radar_chart.queue_redraw()
	
	# Cek apakah sudah ditesting (Cupping)
	var quality = float(item.get("quality_score", -1.0))
	
	if quality < 0.0:
		# Belum di testing!
		if val_rating: val_rating.text = "-"
		if val_speciality: val_speciality.text = "Untested"
		if val_note: val_note.text = "This coffee hasn't been cupped yet, so its grade and quality score are still unknown."
	else:
		# Sudah di testing!
		if val_rating: val_rating.text = str(round(quality))
			
		var grade_str = "Commercial"
		if quality >= 90: grade_str = "Outstanding"
		elif quality >= 85: grade_str = "Excellent"
		elif quality >= 80: grade_str = "Very Good"
		if val_speciality: val_speciality.text = grade_str
			
		if val_note:
			val_note.text = "Hasil panen kopi " + variety + " tahun " + str(item.get("batch_year", "")) + ".\nSiap untuk dipasarkan!"
	
	# Update 3D model packaging
	if subviewport_container and subviewport_container.has_method("update_packaging_preview"):
		var pkg_type = item.get("packaging_type", "pouch")
		var pkg_material = item.get("packaging_material", "plastic")
		var pkg_size = float(item.get("packaging_size", 100.0))
		subviewport_container.update_packaging_preview(pkg_type, pkg_material, pkg_size)

func _clear_details() -> void:
	if right_panel:
		var tween = create_tween()
		tween.tween_property(right_panel, "modulate:a", 0.0, 0.2)
		
	val_variety.text = "-"
	val_species.text = "-"
	val_rating.text = "-"
	val_speciality.text = "-"
	if val_note: val_note.text = ""
	
	if radar_chart and radar_chart.has_method("set_item_value"):
		for i in range(6): radar_chart.set_item_value(i, 0.0)
		if radar_chart.has_method("queue_redraw"): radar_chart.queue_redraw()
