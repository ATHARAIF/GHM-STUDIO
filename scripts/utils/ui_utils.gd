extends RefCounted
class_name UIUtils

static func setup_input_blocker(popup_node: Node) -> void:
	if popup_node.has_node("ColorRect"):
		var color_rect = popup_node.get_node("ColorRect")
		color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		if not color_rect.gui_input.is_connected(_on_input_blocker_gui_input.bind(popup_node)):
			color_rect.gui_input.connect(_on_input_blocker_gui_input.bind(popup_node))

static func _on_input_blocker_gui_input(event: InputEvent, popup_node: Node) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		popup_node.get_viewport().set_input_as_handled()

static func build_farm_timeline(timeline_container: Container, circle_size: int = 16, line_len: int = 16, font_size: int = 10, line_height: int = 2, pending_process_id: String = "") -> void:
	if not timeline_container: return
	
	for child in timeline_container.get_children():
		child.queue_free()
		
	var stages = ["Planting", "Weeding", "Pruning", "Suckering", "Harvest"]
	var process_map = ["FP00", "FP01", "FP02", "FP03", "FP04"]
	
	var c_stage = StageManager.current_stage
	var mapped_current_stage = 0
	if c_stage == 0: mapped_current_stage = 0
	elif c_stage == 1: mapped_current_stage = 1
	elif c_stage == 2: mapped_current_stage = 2
	elif c_stage == 3: mapped_current_stage = 3
	elif c_stage >= 4: mapped_current_stage = 4
	
	# Buat 5 stage dot
	for i in range(5):
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var circle = ColorRect.new()
		circle.custom_minimum_size = Vector2(circle_size, circle_size)
		circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var active_batch = StageManager.get_active_farm_batch()
		var actual_process_id = process_map[i]
		
		var is_completed = false
		if active_batch:
			is_completed = active_batch.completed_processes.has(actual_process_id)
			
		var is_processing = false
		if actual_process_id != "FP00":
			if actual_process_id == pending_process_id:
				is_processing = true
			else:
				for dict in StageManager.active_tiles:
					if dict.data.process_id == actual_process_id:
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
		lbl.add_theme_font_size_override("font_size", font_size)
		
		vbox.add_child(circle)
		vbox.add_child(lbl)
		timeline_container.add_child(vbox)
		
		# Garis penghubung
		if i < 4:
			var line = ColorRect.new()
			line.custom_minimum_size = Vector2(line_len, line_height)
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var m = MarginContainer.new()
			m.add_theme_constant_override("margin_bottom", circle_size)
			m.add_child(line)
			line.color = Color(0.5, 0.5, 0.5)
			timeline_container.add_child(m)
