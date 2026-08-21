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
	
	var preview_yield = 0
	var em = Engine.get_main_loop().root.get_node_or_null("StageManager")
	if em and em.current_location and em.current_location.current_tree:
		var raw = em.current_location.current_tree.calculate_harvest_yield()
		var card_effect = 1.0
		if tile_data.has("data") and tile_data["data"] != null:
			card_effect = 1.0 + tile_data["data"].effect_yield
		if tile_data.has("mod_quant_pct"):
			card_effect *= (1.0 + float(tile_data["mod_quant_pct"]))
		preview_yield = int(clamp(raw * cb.accumulated_yield_modifier * card_effect, 0, 5000))
		
	lbl_yield.text = "%d Kg" % preview_yield
	lbl_defect.text = "Defect Rate: %.1f%%" % cb.defect_rate
	
	show()

func _on_confirm() -> void:
	StageManager.resolve_interaction(current_tile_data, true)
	queue_free()
	get_parent().btn_end_turn.disabled = false

func _on_cancel() -> void:
	queue_free()
	get_parent().btn_end_turn.disabled = false
