extends CanvasLayer

@onready var lbl_quality = $popup_panel/margin/content/quality/value
@onready var lbl_yield = $popup_panel/margin/content/yield/value
@onready var lbl_defect = $popup_panel/margin/content/defect_rate/value
@onready var btn_confirm = $popup_panel/margin/content/HBoxContainer/to_hopper
@onready var btn_close = $popup_panel/close
@onready var lbl_title = $CenterContainer/PanelContainer/VBoxContainer/Header/LblTitle

var current_tile_data: Dictionary

func _ready() -> void:
	btn_confirm.pressed.connect(_on_confirm)
	btn_close.pressed.connect(_on_cancel)
	
	UIUtils.setup_input_blocker(self)
		
	btn_confirm.text = "STORE TO HOPPER"
	
	hide()

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
	hide()
	get_parent().btn_end_turn.disabled = false

func _on_cancel() -> void:
	hide()
	get_parent().btn_end_turn.disabled = false
