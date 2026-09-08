extends CanvasLayer

@export var outline_color: Color = Color(1.0, 0.8, 0.0, 1.0) # Emas
@export var outline_width: float = 3.0

@onready var viewport: SubViewport = SubViewport.new()
@onready var camera: Camera3D = Camera3D.new()
@onready var outline_rect: TextureRect = TextureRect.new()

func _ready():
	layer = 0 # Di bawah UI, di atas 3D
	
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	
	# Hanya melihat layer 2 (bit 1, value 2)
	camera.cull_mask = 2
	viewport.add_child(camera)
	
	outline_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	outline_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var vp_tex = viewport.get_texture()
	outline_rect.texture = vp_tex
	
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0, 0.8, 0.0, 1.0);
uniform float outline_width = 3.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// Jika pixel ini transparan (bukan bagian dari benda)
	if (col.a < 0.1) {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float a = 0.0;
		a += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
		a += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
		a += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
		a += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
		a += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
		
		// Jika ada pixel tetangga yang solid, berarti ini pinggiran siluet!
		if (a > 0.0) {
			COLOR = outline_color;
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		// Pixel benda aslinya disembunyikan agar tembus ke layar utama
		COLOR = vec4(0.0);
	}
}
"""
	mat.shader = shader
	mat.set_shader_parameter("outline_color", outline_color)
	mat.set_shader_parameter("outline_width", outline_width)
	outline_rect.material = mat
	
	add_child(outline_rect)
	
	_on_size_changed()
	get_viewport().size_changed.connect(_on_size_changed)

func _on_size_changed():
	viewport.size = get_viewport().get_visible_rect().size

func _process(delta):
	var root_vp = get_viewport()
	var main_cam = root_vp.get_camera_3d()
	if main_cam and is_instance_valid(main_cam):
		if viewport.world_3d != root_vp.world_3d:
			viewport.world_3d = root_vp.world_3d
			
		camera.global_transform = main_cam.global_transform
		camera.projection = main_cam.projection
		camera.fov = main_cam.fov
		camera.size = main_cam.size
		camera.near = main_cam.near
		camera.far = main_cam.far
		camera.h_offset = main_cam.h_offset
		camera.v_offset = main_cam.v_offset
		camera.keep_aspect = main_cam.keep_aspect
		camera.attributes = main_cam.attributes

func apply_highlight(node: Node, enable: bool):
	if node is VisualInstance3D:
		node.set_layer_mask_value(2, enable)
	for child in node.get_children():
		apply_highlight(child, enable)
