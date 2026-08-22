extends Node3D

@onready var background = $background
@onready var label_lahan = $lahan
@onready var label_turn = $turn
@onready var label_indicator = $interaction_indicator

@export_group("Colors")
@export var default_bg_color: Color = Color(0.0, 0.0, 0.0, 0.4)
@export var ready_bg_color: Color = Color(0.1, 0.8, 0.7, 0.6)

@export_group("Animation")
@export var pulse_speed: float = 4.0
@export var bounce_height: float = 0.1

var label_data: Dictionary = {}
var initialized: bool = false

var is_ready_state: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	if not background or not label_lahan or not label_turn or not label_indicator:
		return
		
	# Setup materials to be unique so pulsing only affects this tile
	var mat = background.material_override
	if mat:
		background.material_override = mat.duplicate()
	else:
		background.material_override = StandardMaterial3D.new()
		background.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
	# Instead of overwriting default_bg_color with the material's color, 
	# we set the material's color to our exported default_bg_color!
	background.material_override.albedo_color = default_bg_color
	
	# Initial state
	label_indicator.hide()
	label_turn.show()

	# Calculate base global positions for the fixed_rotation logic
	var root_node = get_parent()
	var original_rot_y = 0.0
	if root_node:
		original_rot_y = root_node.rotation.y
		root_node.rotation.y = 0.0
		root_node.force_update_transform()
		
	var bg_global_pos = background.global_position
	
	for child in [label_lahan, label_turn, label_indicator]:
		if child and is_instance_valid(child):
			label_data[child] = {
				"base_global_offset": child.global_position - bg_global_pos,
				"base_global_rot_y": child.global_rotation.y
			}
			
	if root_node:
		root_node.rotation.y = original_rot_y
		root_node.force_update_transform()
		
	initialized = true

func _process(delta: float) -> void:
	if not initialized or not background:
		return
		
	# 1. FIXED ROTATION LOGIC
	var bg_global_pos = background.global_position
	for child in [label_lahan, label_turn, label_indicator]:
		if child and label_data.has(child):
			var data = label_data[child]
			
			# Restore rotation
			var rot = child.global_rotation
			rot.y = data.base_global_rot_y
			child.global_rotation = rot
			
			# Restore layout position offset
			child.global_position = bg_global_pos + data.base_global_offset
			
	# 2. PULSING ANIMATION FOR READY STATE
	if is_ready_state:
		pulse_time += delta * pulse_speed
		# Lerp color between default and ready color using sine wave
		var factor = (sin(pulse_time) + 1.0) / 2.0 # 0.0 to 1.0
		background.material_override.albedo_color = default_bg_color.lerp(ready_bg_color, 0.4 + (factor * 0.6))
		
		# Slight bounce on indicator
		var indicator_data = label_data[label_indicator]
		var bounce_offset = Vector3(0, factor * bounce_height, 0)
		label_indicator.global_position = bg_global_pos + indicator_data.base_global_offset + bounce_offset
	else:
		background.material_override.albedo_color = default_bg_color
		pulse_time = 0.0

func set_lahan_name(text: String) -> void:
	if label_lahan:
		label_lahan.text = text

func set_turn(turn: int) -> void:
	if label_turn:
		label_turn.text = str(max(0, turn))

func set_ready_state(ready: bool) -> void:
	is_ready_state = ready
	if is_ready_state:
		label_turn.hide()
		label_indicator.show()
	else:
		label_turn.show()
		label_indicator.hide()
