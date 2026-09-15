extends Control

const FarmCardScene: PackedScene = preload("res://scenes/tiles/farm/farm_card.tscn")

@onready var cards_row: HBoxContainer = $MainPanel/CenterContainer/CardsRow

func _ready() -> void:
	print("terroir_tab.gd nempel di node: ", get_path())
	print("cards_row ketemu: ", cards_row)
	StageManager.farm_locations_changed.connect(_refresh_cards)
	_refresh_cards()

func _refresh_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()

	var locations: Array = []
	for location in StageManager.farm_locations:
		if location.owned:
			locations.append(location)

	for location in locations:
		if not location:
			continue
		var card = FarmCardScene.instantiate()
		cards_row.add_child(card)
		_populate_card(card, location)

func _populate_card(card: Node, location: FarmLocation) -> void:
	var tree: CoffeeTreeData = location.current_tree
	var var_data: CoffeeVariety = location.variety_data

	var lbl_location_name: Label = card.get_node_or_null("VBox/HeaderOverflow/HeaderBar/LblLocationName")

	# --- Baris persentase Sand/Clay/Loam (kotak terpisah di atas) ---
	var val_sand_pct: Label = card.get_node_or_null("VBox/ContentPad/VBox2/PctPanel/PctRow/SandBox/ValSandPct")
	var val_clay_pct: Label = card.get_node_or_null("VBox/ContentPad/VBox2/PctPanel/PctRow/ClayBox/ValClayPct")
	var val_loam_pct: Label = card.get_node_or_null("VBox/ContentPad/VBox2/PctPanel/PctRow/LoamBox/ValLoamPct")

	# --- Grid data biasa (Sand/Clay/Loam TIDAK ada lagi di sini) ---
	var val_exposure: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValExposure")
	var val_altitude: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValAltitude")
	var val_slope: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValSlope")
	var val_ph: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValPh")
	var val_terracing: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValTerracing")
	var val_irrigation: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValIrrigation")
	var val_age: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValAge")
	var val_variety: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValVariety")
	var val_density: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValDensity")
	var val_health: Label = card.get_node_or_null("VBox/ContentPad/VBox2/Grid/ValHealth")

	var btn_manage: Button = card.get_node_or_null("VBox/ContentPad/VBox2/ButtonRow/BtnManageEmployee")
	var btn_disable: Button = card.get_node_or_null("VBox/ContentPad/VBox2/ButtonRow/BtnDisable")

	if lbl_location_name: lbl_location_name.text = location.location_name

	if val_sand_pct: val_sand_pct.text = "%.0f%%" % location.soil_sand
	if val_clay_pct: val_clay_pct.text = "%.0f%%" % location.soil_clay
	if val_loam_pct: val_loam_pct.text = "%.0f%%" % location.soil_loam

	if val_exposure: val_exposure.text = location.exposure
	if val_altitude: val_altitude.text = "%d masl" % location.altitude
	if val_slope: val_slope.text = "%.0f%%" % location.slope
	if val_ph: val_ph.text = "%.1f" % location.ph_level
	if val_terracing: val_terracing.text = "Yes" if location.has_terracing else "No"
	if val_irrigation: val_irrigation.text = "Yes" if location.has_irrigation else "No"

	if tree:
		if val_age: val_age.text = "%.0f Years" % tree.age_years
		if val_variety: val_variety.text = var_data.variety_name if var_data else "Unknown"
		if val_density: val_density.text = "%d Trees/Ha" % tree.planting_density
		if val_health: val_health.text = "%.0f%%" % tree.health_pct

	if btn_manage:
		btn_manage.pressed.connect(func(): _on_manage_employee_pressed(location))
	if btn_disable:
		btn_disable.pressed.connect(func(): _on_disable_pressed(location))

func _on_manage_employee_pressed(location: FarmLocation) -> void:
	# TODO: buka UI manage employee untuk lahan ini
	print("Manage employee ditekan untuk: ", location.location_name)

func _on_disable_pressed(location: FarmLocation) -> void:
	# TODO: hubungkan ke sistem disable lahan
	print("Disable ditekan untuk: ", location.location_name)
