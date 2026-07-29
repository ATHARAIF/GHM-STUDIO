extends CanvasLayer

@onready var btn_process = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/BtnProcess
@onready var btn_sell = $CenterContainer/PanelContainer/VBoxContainer/HBoxContainer/BtnSell
@onready var btn_close = $CenterContainer/PanelContainer/VBoxContainer/Header/BtnClose
@onready var lbl_quality = $CenterContainer/PanelContainer/VBoxContainer/VBoxData/LblQualityValue
@onready var lbl_quantity = $CenterContainer/PanelContainer/VBoxContainer/VBoxData/LblQuantityValue

var current_tile_data: Dictionary

func _ready() -> void:
	btn_process.pressed.connect(_on_process_pressed)
	btn_sell.pressed.connect(_on_sell_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	
	if has_node("ColorRect"):
		$ColorRect.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton or event is InputEventMouseMotion:
				get_viewport().set_input_as_handled()
		)
	
	hide()
	
func show_popup(tile_data: Dictionary) -> void:
	current_tile_data = tile_data
	
	# Tampilkan hasil panen saat ini
	var batch = StageManager.get_oldest_ready_batch("WP02")
	if batch:
		# Dummy quality calculation based on aroma + body - defect
		var quality_score = (batch.aroma + batch.body) - batch.defect_rate
		var quality_text = "Good"
		if quality_score > 50: quality_text = "Excellent"
		elif quality_score < 10: quality_text = "Poor"
		
		lbl_quality.text = quality_text
		lbl_quantity.text = str(batch.cherry_kg) + " kg"
		
	show()

func _on_process_pressed() -> void:
	StageManager.resolve_interaction(current_tile_data, true)
	hide()
	get_parent().btn_end_turn.disabled = false

func _on_sell_pressed() -> void:
	StageManager.resolve_interaction(current_tile_data, false)
	hide()
	get_parent().btn_end_turn.disabled = false

func _on_close_pressed() -> void:
	hide()
	get_parent().btn_end_turn.disabled = false
