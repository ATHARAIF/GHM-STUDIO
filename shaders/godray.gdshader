shader_type canvas_item;

uniform vec4 ray_color : source_color = vec4(1.0, 0.9, 0.65, 0.4);
uniform float angle : hint_range(0.0, 360.0) = -45.0;
uniform float ray_speed = 0.8;
uniform float ray_density = 25.0;
uniform float pulse_speed = 1.5;
uniform float pulse_intensity = 0.3;
uniform float pulse_variation = 1.5; 
uniform float fade_strength = 1.2;

uniform sampler2D cloud_noise : repeat_enable; 
uniform vec2 cloud_direction = vec2(0.05, 0.02); 
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.4); 

uniform float cloud_scale_base = 1.0;
uniform float cloud_scale_randomness = 1.5;
uniform float cloud_speed_variation = 1.2;

uniform float cloud_threshold = 0.4;
uniform float cloud_smoothness = 0.1; 

void fragment() {
    float angle_rad = radians(angle);
    vec2 centered_uv = UV - 0.5;
    
    float cos_a = cos(angle_rad);
    float sin_a = sin(angle_rad);
    float rotated_x = centered_uv.x * cos_a - centered_uv.y * sin_a;
    
    float time_offset = TIME * ray_speed;
    
    float rays1 = sin((rotated_x - time_offset) * ray_density);
    float rays2 = sin((rotated_x - time_offset * 1.5) * (ray_density * 0.5));
    float combined_rays = smoothstep(-0.5, 1.0, rays1 * rays2);
    
    float random_pulse_offset = rotated_x * ray_density * pulse_variation;
    float pulse = 1.0 - pulse_intensity + (sin(TIME * pulse_speed + random_pulse_offset) * 0.5 + 0.5) * pulse_intensity;
    
    float fade = clamp(1.0 - (UV.y * fade_strength), 0.0, 1.0);
    
    vec4 ray_layer = vec4(ray_color.rgb, ray_color.a * combined_rays * pulse * fade);
    
    vec2 uv1 = UV * cloud_scale_base + (TIME * cloud_direction);
    float cloud1 = texture(cloud_noise, uv1).r;
    
    float scale2 = cloud_scale_base + cloud_scale_randomness;
    vec2 speed2 = cloud_direction * (1.0 + cloud_speed_variation);
    vec2 uv2 = (UV + vec2(0.35, 0.71)) * scale2 + (TIME * speed2);
    float cloud2 = texture(cloud_noise, uv2).r;
    
    float scale3 = cloud_scale_base + (cloud_scale_randomness * 2.0);
    vec2 speed3 = cloud_direction * (1.0 + (cloud_speed_variation * 2.0));
    vec2 uv3 = (UV + vec2(0.83, 0.29)) * scale3 + (TIME * speed3);
    float cloud3 = texture(cloud_noise, uv3).r;
    
    float merged_clouds = max(cloud1, max(cloud2, cloud3));
    
    float solid_cloud = smoothstep(cloud_threshold, cloud_threshold + cloud_smoothness, merged_clouds);
    
    vec4 shadow_layer = vec4(shadow_color.rgb, shadow_color.a * solid_cloud);
    
    float final_a = ray_layer.a + shadow_layer.a * (1.0 - ray_layer.a);
    vec3 final_rgb = vec3(0.0);
    
    if (final_a > 0.0) {
        final_rgb = (ray_layer.rgb * ray_layer.a + shadow_layer.rgb * shadow_layer.a * (1.0 - ray_layer.a)) / final_a;
    }
    
    COLOR = vec4(final_rgb, final_a);
}