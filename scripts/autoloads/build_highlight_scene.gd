extends SceneTree

func _init():
	var canvas = CanvasLayer.new()
	canvas.name = "SilhouetteHighlight"
	canvas.layer = 0
	
	var vp = SubViewport.new()
	vp.name = "SubViewport"
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.add_child(vp)
	vp.owner = canvas
	
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	cam.cull_mask = 2
	vp.add_child(cam)
	cam.owner = canvas
	
	var rect = TextureRect.new()
	rect.name = "TextureRect"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)
	rect.owner = canvas
	
	var script = preload("res://scripts/autoloads/silhouette_highlight.gd")
	canvas.set_script(script)
	
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(1.0, 0.8, 0.0, 1.0);
uniform float outline_width = 3.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
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
        
        if (a > 0.0) {
            COLOR = outline_color;
        } else {
            COLOR = vec4(0.0);
        }
    } else {
        COLOR = vec4(0.0);
    }
}
"""
	mat.shader = shader
	rect.material = mat
	
	var packed = PackedScene.new()
	packed.pack(canvas)
	ResourceSaver.save(packed, "res://scenes/autoloads/silhouette_highlight.tscn")
	
	print("DONE")
	quit()
