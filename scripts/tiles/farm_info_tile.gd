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
		
	var stages = ["Planting", "Weeding", "Pruning", "Suckering", "Harvest"]
	var stage_id_map = [0, 1, 2, -1, 3] # -1 berarti card belum dibuat
	
	var c_stage = StageManager.current_stage
	var mapped_current_stage = 0
	if c_stage == 0: mapped_current_stage = 0
	elif c_stage == 1: mapped_current_stage = 1
	elif c_stage == 2: mapped_current_stage = 2
	elif c_stage >= 3: mapped_current_stage = 4
	
	# Buat 5 stage dot
	for i in range(5):
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var circle = ColorRect.new()
		circle.custom_minimum_size = Vector2(24, 24)
		circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var active_batch = StageManager.get_active_farm_batch()
		var actual_stage_id = stage_id_map[i]
		
		var is_completed = false
		if actual_stage_id != -1 and active_batch:
			is_completed = active_batch.completed_stages.has(actual_stage_id)
			
		var is_processing = false
		if actual_stage_id != -1:
			for dict in StageManager.active_tiles:
				if dict.data.stage_id == actual_stage_id:
					is_processing = true
					break
		
		# Kasus khusus Planting (0) selalu hijau karena sudah ada dari awal
		if i == 0:
			is_completed = true
				
		if is_completed:
			circle.color = Color(0.2, 0.8, 0.2) # Hijau (Selesai)
		elif is_processing:
			circle.color = Color(1.0, 0.8, 0.0) # Kuning (Sekarang)
		elif i < mapped_current_stage:
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
		if i < 4:
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
