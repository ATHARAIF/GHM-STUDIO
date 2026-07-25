extends CanvasLayer

signal confirmed(method: String, intensity: float)
signal cancelled()

@onready var btn_single = $CenterContainer/PanelContainer/VBoxContainer/VBoxMethod/HBoxMethods/BtnSingle
@onready var btn_multi = $CenterContainer/PanelContainer/VBoxContainer/VBoxMethod/HBoxMethods/BtnMulti
@onready var slider_intensity = $CenterContainer/PanelContainer/VBoxContainer/VBoxIntensity/SliderIntensity
@onready var lbl_intensity_val = $CenterContainer/PanelContainer/VBoxContainer/VBoxIntensity/LblIntensityVal

@onready var btn_confirm = $CenterContainer/PanelContainer/VBoxContainer/HBoxButtons/BtnConfirm
@onready var btn_cancel = $CenterContainer/PanelContainer/VBoxContainer/HBoxButtons/BtnCancel
@onready var btn_close = $CenterContainer/PanelContainer/VBoxContainer/Header/BtnClose

var selected_method: String = "Single-Stem"

func _ready() -> void:
	btn_single.pressed.connect(func(): _select_method("Single-Stem"))
	btn_multi.pressed.connect(func(): _select_method("Multi-Stem"))
	
	slider_intensity.value_changed.connect(_on_slider_changed)
	
	btn_confirm.pressed.connect(_on_confirm)
	btn_cancel.pressed.connect(_on_cancel)
	btn_close.pressed.connect(_on_cancel)
	
	_select_method("Single-Stem")
	_on_slider_changed(slider_intensity.value)
	
	hide()

func _select_method(method: String) -> void:
	selected_method = method
	if method == "Single-Stem":
		btn_single.modulate = Color(0.2, 0.8, 0.2)
		btn_multi.modulate = Color(1.0, 1.0, 1.0)
	else:
		btn_single.modulate = Color(1.0, 1.0, 1.0)
		btn_multi.modulate = Color(0.2, 0.8, 0.2)

func _on_slider_changed(val: float) -> void:
	var text = "Medium"
	if val <= 20: text = "Very Low"
	elif val <= 40: text = "Low"
	elif val <= 60: text = "Medium"
	elif val <= 80: text = "High"
	else: text = "Very High"
	
	lbl_intensity_val.text = text

func show_popup() -> void:
	# Reset state if needed
	_select_method("Single-Stem")
	slider_intensity.value = 50.0
	show()

func _on_confirm() -> void:
	hide()
	confirmed.emit(selected_method, slider_intensity.value)

func _on_cancel() -> void:
	hide()
	cancelled.emit()
