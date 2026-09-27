extends Control

@onready var grid_container = $ScrollContainer/GridContainer
@onready var card_template = $ScrollContainer/GridContainer/terroir_card

var empty_label: Label = null

func _ready() -> void:
	if card_template:
		card_template.hide()
		
	empty_label = Label.new()
	empty_label.text = "No Coffee in Storage"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", 24)
	empty_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	empty_label.hide()
	
	# Supaya label 'No Data' tetap di tengah grid
	empty_label.size_flags_horizontal = SIZE_EXPAND_FILL
	grid_container.add_child(empty_label)
		
	visibility_changed.connect(_on_visibility_changed)
	_refresh_list()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_list()

func _refresh_list() -> void:
	for child in grid_container.get_children():
		if child != card_template and child != empty_label:
			child.queue_free()
			
	if not has_node("/root/StageManager"): return
	var stage_manager = get_node("/root/StageManager")
	var batches = stage_manager.batches
	var has_items = false
	
	for year in batches.keys():
		var batch = batches[year]
		
		# 1. Cherry
		if batch.cherry_kg >= 0.099:
			_create_card(batch, "Cherry", batch.cherry_kg)
			has_items = true
			
		# 2. Green Bean
		if batch.green_bean_kg >= 0.099:
			_create_card(batch, "Green Bean", batch.green_bean_kg)
			has_items = true
			
		# 3. Roasted Bean
		var avail_roasted = batch.roasted_bean_kg
		if batch.get("reserved_roasted_bean_kg") != null:
			avail_roasted -= batch.reserved_roasted_bean_kg
			
		if avail_roasted >= 0.099:
			_create_card(batch, "Roasted Bean", avail_roasted)
			has_items = true

	if has_items:
		empty_label.hide()
	else:
		empty_label.show()

func _create_card(batch: CoffeeBatch, type_name: String, amount_kg: float) -> void:
	var card = card_template.duplicate()
	card.show()
	
	var lbl_name = card.get_node_or_null("terroir_header/terroir_name")
	var lbl_species = card.get_node_or_null("terroir_header/terroir_species")
	var lbl_stock = card.get_node_or_null("details/stats/image/HBoxContainer/stock")
	var lbl_rating = card.get_node_or_null("details/stats/chart/rating")
	var radar = card.get_node_or_null("details/stats/chart/radar")
	
	if lbl_name:
		lbl_name.text = str(batch.variety_name) + " " + str(batch.batch_year)
		
	if lbl_species:
		lbl_species.text = str(batch.species_name) + " - " + type_name
		
	if lbl_stock:
		lbl_stock.text = str(snapped(amount_kg, 0.1)) + " Kg"
		
	var quality = float(batch.get_meta("quality_score")) if batch.has_meta("quality_score") else -1.0
	
	if lbl_rating:
		if quality >= 0.0:
			lbl_rating.text = "★ " + str(round(quality))
		else:
			lbl_rating.text = "Untested"
			
	if radar and radar.has_method("set_item_value"):
		radar.key_count = 6
		radar.set_item_title(0, "Sweetness")
		radar.set_item_title(1, "Aroma")
		radar.set_item_title(2, "Acidity")
		radar.set_item_title(3, "Flavor")
		radar.set_item_title(4, "Bitterness")
		radar.set_item_title(5, "Body")
		
		radar.set_item_value(0, batch.sweetness)
		radar.set_item_value(1, batch.aroma)
		radar.set_item_value(2, batch.acidity)
		radar.set_item_value(3, batch.flavor)
		radar.set_item_value(4, batch.bitterness)
		radar.set_item_value(5, batch.body)
		
		if radar.has_method("queue_redraw"):
			radar.queue_redraw()
			
	grid_container.add_child(card)
