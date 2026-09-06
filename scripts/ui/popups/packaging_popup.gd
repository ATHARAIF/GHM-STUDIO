extends Control

# Data State (Nanti diganti jadi ambil dari Hopper/Batch beneran)
var total_yield_grams: float = 2000000.0 # 2000 kg

# Pilihan saat ini
var selected_gramasi: float = 0.0
var selected_bentuk: String = ""
var selected_material: String = ""
var max_packs: int = 0
var current_packs: int = 0

@onready var btn_close = $popup_panel/close

# LEFT SIDE TABS
@onready var tab_container = $popup_panel/margin/hbox/left_side/margin/content/TabContainer
@onready var btn_tab_spec = $popup_panel/margin/hbox/left_side/margin/content/HBoxTabs/BtnTabSpec
@onready var btn_tab_visual = $popup_panel/margin/hbox/left_side/margin/content/HBoxTabs/BtnTabVisual

# Spesifikasi
@onready var hbox_gramasi = $popup_panel/margin/hbox/left_side/margin/content/TabContainer/spec/size_container
@onready var hbox_bentuk = $popup_panel/margin/hbox/left_side/margin/content/TabContainer/spec/type_container
@onready var hbox_material = $popup_panel/margin/hbox/left_side/margin/content/TabContainer/spec/material_container

# Visual
@onready var hbox_logo = $popup_panel/margin/hbox/left_side/margin/content/TabContainer/visual/HBoxTop/VBoxLogo/HBoxLogo
@onready var color_picker = $popup_panel/margin/hbox/left_side/margin/content/TabContainer/visual/HBoxTop/VBoxWarna/ColorPicker
@onready var grid_warna = $popup_panel/margin/hbox/left_side/margin/content/TabContainer/visual/GridWarnaDasar

# RIGHT SIDE
@onready var tex_preview = $popup_panel/margin/hbox/right_side/margin/method_container/TexPreview
@onready var val_qty = $popup_panel/margin/hbox/right_side/margin/method_container/HBoxQty/ValQty
@onready var slider_qty = $popup_panel/margin/hbox/right_side/margin/method_container/SliderQty
@onready var btn_confirm = $popup_panel/margin/hbox/right_side/margin/method_container/BtnConfirm


func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(_on_close)
		
	if slider_qty:
		slider_qty.value_changed.connect(_on_slider_changed)
		slider_qty.value = 0
		
	if btn_confirm:
		btn_confirm.pressed.connect(_on_confirm)
		btn_confirm.disabled = true
		
	# Tab Connections
	var tab_group = ButtonGroup.new()
	if btn_tab_spec and btn_tab_visual:
		btn_tab_spec.button_group = tab_group
		btn_tab_visual.button_group = tab_group
		btn_tab_spec.pressed.connect(func(): tab_container.current_tab = 0)
		btn_tab_visual.pressed.connect(func(): tab_container.current_tab = 1)
		
	_setup_toggle_groups()
	_update_ui()
	UIUtils.setup_input_blocker(self)

func _setup_toggle_groups() -> void:
	var tg_gramasi = ButtonGroup.new()
	if hbox_gramasi:
		for btn in hbox_gramasi.get_children():
			if btn is Button:
				btn.button_group = tg_gramasi
				btn.pressed.connect(func(): _on_gramasi_selected(float(btn.text)))
				
	var tg_bentuk = ButtonGroup.new()
	if hbox_bentuk:
		for btn in hbox_bentuk.get_children():
			if btn is Button:
				btn.button_group = tg_bentuk
				btn.pressed.connect(func(): _on_bentuk_selected(btn.text))
				
	var tg_material = ButtonGroup.new()
	if hbox_material:
		for btn in hbox_material.get_children():
			if btn is Button:
				btn.button_group = tg_material
				btn.pressed.connect(func(): _on_material_selected(btn.text))

func _on_gramasi_selected(val: float) -> void:
	selected_gramasi = val
	_recalculate_max_packs()

func _on_bentuk_selected(val: String) -> void:
	selected_bentuk = val
	_update_ui()

func _on_material_selected(val: String) -> void:
	selected_material = val
	_update_ui()

func _recalculate_max_packs() -> void:
	if selected_gramasi > 0:
		max_packs = int(total_yield_grams / selected_gramasi)
	else:
		max_packs = 0
		
	if slider_qty:
		slider_qty.max_value = max_packs
		if slider_qty.value > max_packs:
			slider_qty.value = max_packs
			
	_update_ui()

func _on_slider_changed(val: float) -> void:
	current_packs = int(val)
	if val_qty:
		val_qty.text = str(current_packs) + " packs"
	_update_ui()

func _update_ui() -> void:
	var is_valid = (selected_gramasi > 0 and selected_bentuk != "" and selected_material != "" and current_packs > 0)
	if btn_confirm:
		btn_confirm.disabled = not is_valid

func _on_confirm() -> void:
	print("Packing Confirmed!")
	print("- Spesifikasi: ", selected_gramasi, "g, ", selected_bentuk, ", ", selected_material)
	print("- Jumlah Pack: ", current_packs, " packs")
	print("- Sisa Yield: ", (total_yield_grams - (current_packs * selected_gramasi)), "g")
	
	queue_free()

func _on_close() -> void:
	queue_free()
