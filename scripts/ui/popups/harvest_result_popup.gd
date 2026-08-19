extends CanvasLayer

@onready var lbl_quality = $CenterContainer/PanelContainer/VBoxContainer/VBoxData/LblQualityValue
@onready var lbl_yield = $CenterContainer/PanelContainer/VBoxContainer/VBoxData/LblQuantityValue
@onready var lbl_defect = $CenterContainer/PanelContainer/VBoxContainer/VBoxData/LblDefect
@onready var btn_confirm = $CenterContainer/PanelContainer/VBoxContainer/BtnConfirm
@onready var btn_close = $CenterContainer/PanelContainer/VBoxContainer/Header/BtnClose
@onready var lbl_title = $CenterContainer/PanelContainer/VBoxContainer/Header/LblTitle

var current_tile_data: Dictionary

func _ready() -> void:
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	UIUtils.setup_input_blocker(self)
		
	btn_confirm.text = "STORE TO HOPPER"
	

func show_popup(tile_data: Dictionary) -> void:
	current_tile_data = tile_data
	
	# Display stats
	var cb = StageManager.get_active_farm_batch()
		
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
	
	lbl_yield.text = "%d Kg" % cb.cherry_kg
	lbl_defect.text = "Defect Rate: %.1f%%" % cb.defect_rate
	
	show()

func _on_confirm() -> void:
	StageManager.resolve_interaction(current_tile_data, true)
	queue_free()
	get_parent().btn_end_turn.disabled = false

func _on_cancel() -> void:
	queue_free()
	get_parent().btn_end_turn.disabled = false
