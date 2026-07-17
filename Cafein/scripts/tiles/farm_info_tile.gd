extends Node3D

@onready var popup_ui: CanvasLayer = $PopupUI
@onready var lbl_location: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/LblLocation
@onready var lbl_altitude: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAltitude
@onready var lbl_soil: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValSoil
@onready var lbl_aroma: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAroma
@onready var lbl_body: Label = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValBody
@export var lbl_acidity: Label = null
@export var btn_close: Button = null
@export var timeline_container: HBoxContainer = null

var location: FarmLocation

func _ready() -> void:
	# Hubungkan references manual jika tidak ada
	popup_ui = $PopupUI
	lbl_location = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/LblLocation
	lbl_altitude = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAltitude
	lbl_soil = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValSoil
	lbl_aroma = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAroma
	lbl_body = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValBody
	lbl_acidity = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/GridContainer/ValAcidity
	btn_close = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Header/BtnClose
	timeline_container = $PopupUI/CenterContainer/PanelContainer/VBoxContainer/Timeline
	
	location = StageManager.current_location
	
	if location:
		lbl_location.text = location.location_name
		lbl_altitude.text = "%dm" % location.altitude
		lbl_soil.text = "%d/100" % location.soil_quality
		lbl_aroma.text = "+%d" % location.base_aroma
		lbl_body.text = "+%d" % location.base_body
		lbl_acidity.text = "%d" % location.base_acidity
		
	btn_close.pressed.connect(func(): popup_ui.hide())
	popup_ui.hide()
	
	# Sembunyikan label 3D karena sekarang kita pakai UI Popup
	if has_node("Label3D"):
		$Label3D.hide()

func _update_timeline() -> void:
	if not timeline_container: return
	
	for child in timeline_container.get_children():
		child.queue_free()
		
	var stages = ["Planting", "Weeding", "Pruning", "Harvest", "Cleaning", "Dry"]
	
	# Buat 6 stage dot
	for i in range(6):
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var circle = ColorRect.new()
		circle.custom_minimum_size = Vector2(24, 24)
		circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var is_completed = StageManager.coffee_batch and StageManager.coffee_batch.completed_stages.has(i)
		var is_processing = false
		for dict in StageManager.active_tiles:
			if dict.data.stage_id == i:
				is_processing = true
				break
		
		# Kasus khusus Planting (0)
		if i == 0:
			var turn_in_year = ((StageManager.current_turn - 1) % 20) + 1
			if turn_in_year >= 3:
				is_completed = true
			else:
				is_processing = true
				
		if is_completed:
			circle.color = Color(0.2, 0.8, 0.2) # Hijau (Selesai)
		elif is_processing:
			circle.color = Color(1.0, 0.8, 0.0) # Kuning (Sekarang)
		elif i < StageManager.current_stage:
			circle.color = Color(0.8, 0.2, 0.2) # Merah (Terlewati)
		else:
			circle.color = Color(0.4, 0.4, 0.4) # Abu-abu (Belum)
			
		var lbl = Label.new()
		lbl.text = stages[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		
		vbox.add_child(circle)
		vbox.add_child(lbl)
		timeline_container.add_child(vbox)
		
		# Garis penghubung
		if i < 5:
			var line = ColorRect.new()
			line.custom_minimum_size = Vector2(30, 4)
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			# Shift line up slightly so it aligns with circles (ignoring labels)
			var m = MarginContainer.new()
			m.add_theme_constant_override("margin_bottom", 20)
			m.add_child(line)
			
			line.color = Color(0.5, 0.5, 0.5)
			timeline_container.add_child(m)

func _on_static_body_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_timeline()
		popup_ui.show()
