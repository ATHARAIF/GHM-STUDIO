extends CanvasLayer

var total_yield_grams: float = 0.0

# Current Selections
var selected_size: float = 0.0
var selected_type: String = ""
var selected_material: String = ""
var max_packs: int = 0
var current_packs: int = 0

var current_tile: Node3D
var current_card_data: Resource
var target_batch: Resource

@export var packs_per_turn: int = 500 # Setting in Inspector: 1 Turn processes how many pcs

@onready var btn_close = $CenterContainer/panel/close

@onready var btn_tab_spec = $CenterContainer/panel/content/setup/left/tab/toggle_buttons/Specification
@onready var btn_tab_visual = $CenterContainer/panel/content/setup/left/tab/toggle_buttons/Visual

@onready var content_specification = $CenterContainer/panel/content/setup/left/tab_content/spesification
@onready var hbox_size = $CenterContainer/panel/content/setup/left/tab_content/spesification/size/toggle_buttons
@onready var btn_size_100 = $"CenterContainer/panel/content/setup/left/tab_content/spesification/size/toggle_buttons/100"
@onready var btn_size_200 = $"CenterContainer/panel/content/setup/left/tab_content/spesification/size/toggle_buttons/200"
@onready var btn_size_500 = $"CenterContainer/panel/content/setup/left/tab_content/spesification/size/toggle_buttons/500"
@onready var btn_size_1000 = $"CenterContainer/panel/content/setup/left/tab_content/spesification/size/toggle_buttons/1000"

@onready var hbox_type = $CenterContainer/panel/content/setup/left/tab_content/spesification/type/toggle_buttons
@onready var btn_type_pouch = $CenterContainer/panel/content/setup/left/tab_content/spesification/type/toggle_buttons/pouch
@onready var btn_type_fbtom = $CenterContainer/panel/content/setup/left/tab_content/spesification/type/toggle_buttons/f_bottom
@onready var btn_type_gusset = $CenterContainer/panel/content/setup/left/tab_content/spesification/type/toggle_buttons/gusset

@onready var hbox_material = $CenterContainer/panel/content/setup/left/tab_content/spesification/material/toggle_buttons
@onready var btn_material_plastic = $CenterContainer/panel/content/setup/left/tab_content/spesification/material/toggle_buttons/plastic
@onready var btn_material_paper = $CenterContainer/panel/content/setup/left/tab_content/spesification/material/toggle_buttons/paper
@onready var btn_material_alumunium = $CenterContainer/panel/content/setup/left/tab_content/spesification/material/toggle_buttons/alumunium

@onready var subviewpor_container = $CenterContainer/panel/content/setup/right/viewport/PanelContainer/Control/SubViewportContainer
@onready var pcs_value = $CenterContainer/panel/content/setup/right/viewport/slider/value/pcs_value/pcs_value
@onready var slider_qty = $CenterContainer/panel/content/setup/right/viewport/slider/container/slider
@onready var pct_slider = $CenterContainer/panel/content/setup/right/viewport/slider/container/value_pct
@onready var turn_expect = $CenterContainer/panel/content/setup/right/viewport/turn/value

@onready var btn_confirm = $CenterContainer/panel/content/confirmation/confirm
@onready var content_visual = $CenterContainer/panel/content/setup/left/tab_content/visual

# Header Labels
@onready var val_variety = get_node_or_null("CenterContainer/panel/content/bean_name/variety")
@onready var val_batch = get_node_or_null("CenterContainer/panel/content/setup/left/bean_data/data1/value")
@onready var val_yield = get_node_or_null("CenterContainer/panel/content/setup/left/bean_data/data2/value")
@onready var lbl_arabica = get_node_or_null("CenterContainer/panel/content/bean_name/arabica")
@onready var lbl_robusta = get_node_or_null("CenterContainer/panel/content/bean_name/robusta")

func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(_on_close)
		
	if slider_qty:
		slider_qty.value_changed.connect(_on_slider_changed)
		slider_qty.value = 0
		
	if btn_confirm:
		btn_confirm.pressed.connect(_on_confirm)
		btn_confirm.disabled = true
		
	# Tab Connections (Manual Toggling)
	var tab_group = ButtonGroup.new()
	if btn_tab_spec and btn_tab_visual:
		btn_tab_spec.button_group = tab_group
		btn_tab_visual.button_group = tab_group
		
		# Saat diklik, atur visibility secara manual
		btn_tab_spec.pressed.connect(_show_specification_tab)
		btn_tab_visual.pressed.connect(_show_visual_tab)
		
		# Set Visual non-interaktif untuk sementara
		btn_tab_visual.disabled = true
		btn_tab_spec.button_pressed = true
		
	_show_specification_tab()
	
	_setup_toggle_groups()
	_update_ui()
	UIUtils.setup_input_blocker(self)
	
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_requested.connect(_on_card_placement_interaction_requested)
		
	hide()

func _show_specification_tab() -> void:
	if content_specification: content_specification.show()
	if content_visual: content_visual.hide()

func _show_visual_tab() -> void:
	if content_specification: content_specification.hide()
	if content_visual: content_visual.show()

func _setup_toggle_groups() -> void:
	var tg_size = ButtonGroup.new()
	tg_size.allow_unpress = false
	if hbox_size:
		for btn in hbox_size.get_children():
			if btn is Button:
				btn.button_group = tg_size
				btn.pressed.connect(func(): _on_size_selected(float(btn.name)))
				
	var tg_type = ButtonGroup.new()
	tg_type.allow_unpress = false
	if hbox_type:
		for btn in hbox_type.get_children():
			if btn is Button:
				btn.button_group = tg_type
				btn.pressed.connect(func(): _on_type_selected(btn.name))
				
	var tg_material = ButtonGroup.new()
	tg_material.allow_unpress = false
	if hbox_material:
		for btn in hbox_material.get_children():
			if btn is Button:
				btn.button_group = tg_material
				btn.pressed.connect(func(): _on_material_selected(btn.name))
				
	if btn_size_200:
		btn_size_200.button_pressed = true
		_on_size_selected(200.0)
	if btn_type_pouch:
		btn_type_pouch.button_pressed = true
		_on_type_selected("pouch")
	if btn_material_plastic:
		btn_material_plastic.button_pressed = true
		_on_material_selected("plastic")

func _on_size_selected(val: float) -> void:
	selected_size = val
	_recalculate_max_packs()

func _on_type_selected(val: String) -> void:
	selected_type = val
	_update_ui()

func _on_material_selected(val: String) -> void:
	selected_material = val
	_update_ui()

func _recalculate_max_packs() -> void:
	if selected_size > 0:
		# Tambahkan epsilon kecil untuk mencegah error presisi pembagian float sebelum dicast ke int (kebawah)
		max_packs = int((total_yield_grams / selected_size) + 0.00001)
	else:
		max_packs = 0
		
	if slider_qty:
		slider_qty.max_value = max_packs
		if slider_qty.value > max_packs:
			slider_qty.value = max_packs
			
	_update_ui()

func _on_slider_changed(val: float) -> void:
	current_packs = int(val)
	if pcs_value:
		pcs_value.text = str(current_packs) + " pcs"
	if pct_slider:
		var pct = 0.0
		if max_packs > 0:
			pct = (float(current_packs) / float(max_packs)) * 100.0
		pct_slider.text = str(round(pct)) + "%"
	_update_ui()

func _update_ui() -> void:
	var is_valid = true
	
	if selected_size <= 0: is_valid = false
	if selected_type == "": is_valid = false
	if selected_material == "": is_valid = false
	if current_packs <= 0: is_valid = false
	
	if btn_confirm:
		btn_confirm.disabled = not is_valid
		
	if pcs_value:
		pcs_value.text = str(current_packs) + " pcs"
		
	if pct_slider:
		var pct = 0.0
		if max_packs > 0:
			pct = (float(current_packs) / float(max_packs)) * 100.0
		pct_slider.text = str(round(pct)) + "%"
		
	if turn_expect:
		var calculated_turns = max(2, int(ceil(float(current_packs) / float(packs_per_turn))))
		turn_expect.text = str(calculated_turns) + " Turn"
		
	_update_3d_model()

func _update_3d_model() -> void:
	if subviewpor_container and subviewpor_container.has_method("update_packaging_preview"):
		subviewpor_container.update_packaging_preview(selected_type, selected_material, selected_size)

func _on_confirm() -> void:
	if current_packs <= 0: return
	
	if target_batch and target_batch.get("roasted_bean_kg") != null:
		var kg_used = (current_packs * selected_size) / 1000.0
		if target_batch.get("reserved_roasted_bean_kg") != null:
			target_batch.reserved_roasted_bean_kg += kg_used
		else:
			target_batch.roasted_bean_kg = max(0.0, target_batch.roasted_bean_kg - kg_used)
		
	var calculated_turns = max(2, int(ceil(float(current_packs) / float(packs_per_turn))))
	
	if has_node("/root/EventManager"):
		var extra_data = {
			"packs": current_packs,
			"size": selected_size,
			"type": selected_type,
			"material": selected_material,
			"turn_duration": calculated_turns,
			"target_batch_year": target_batch.batch_year if target_batch else 0
		}
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_confirmed.emit("Packing", current_tile, current_card_data, extra_data)
		
	queue_free()

func _on_close() -> void:
	if has_node("/root/EventManager"):
		var em = get_node("/root/EventManager")
		em.card_placement_interaction_cancelled.emit("Packing", current_tile, current_card_data)
	queue_free()

func _on_card_placement_interaction_requested(card_name: String, tile: Node3D, card_data: Resource) -> void:
	if card_name == "Packing":
		current_tile = tile
		current_card_data = card_data
		show_popup()

func show_popup() -> void:
	total_yield_grams = 0.0
	
	if StageManager.has_method("get_oldest_ready_batch"):
		target_batch = StageManager.get_oldest_ready_batch("DP03")
		
	if target_batch:
		if target_batch.roasted_bean_kg <= 0 and target_batch.cherry_kg > 0:
			# Auto-fix untuk old batch yang belum ke-convert!
			target_batch.roasted_bean_kg = target_batch.cherry_kg * 0.2 * 0.85
			
		if val_batch: 
			val_batch.text = str(target_batch.batch_year)
		if val_variety: val_variety.text = str(target_batch.variety_name)
		if val_yield: val_yield.text = "%.1f kg" % target_batch.roasted_bean_kg
		if lbl_arabica: lbl_arabica.visible = (target_batch.species_name == "Arabica")
		if lbl_robusta: lbl_robusta.visible = (target_batch.species_name == "Robusta")
		
		if target_batch.get("roasted_bean_kg") != null and target_batch.roasted_bean_kg > 0:
			var available = target_batch.roasted_bean_kg
			if target_batch.get("reserved_roasted_bean_kg") != null:
				available = max(0.0, available - target_batch.reserved_roasted_bean_kg)
			# Gunakan round() untuk menghindari hilangnya presisi float (misal 504.1 * 1000 jadi 504099.999)
			total_yield_grams = round(available * 1000.0)
			
	_recalculate_max_packs()
	if slider_qty:
		slider_qty.value = max_packs * 0.5
		
	var lbl_pcs = get_node_or_null("CenterContainer/panel/content/setup/right/viewport/slider/value/pcs_value/pcs")
	if lbl_pcs: lbl_pcs.hide()
		
	show()
