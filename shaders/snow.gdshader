shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// ==========================================
// PARAMETER WARNA LINGKUNGAN (WINTER VIBE)
// ==========================================
uniform vec4 winter_color : source_color = vec4(0.55, 0.7, 0.85, 1.0);
uniform float winter_blend : hint_range(0.0, 1.0) = 0.3;
uniform float saturation : hint_range(0.0, 1.0) = 0.7;

// ==========================================
// PARAMETER SALJU
// ==========================================
uniform float snow_speed : hint_range(0.1, 5.0) = 0.5;
uniform float snow_density : hint_range(0.0, 1.0) = 0.6;
uniform float wind_sway : hint_range(0.0, 5.0) = 2.0; 
uniform float sway_speed : hint_range(0.1, 5.0) = 1.5;
uniform float snow_size : hint_range(0.01, 0.5) = 0.08;
uniform vec4 snow_color : source_color = vec4(1.0, 1.0, 1.0, 0.8);

// Fungsi Random 2D
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // 1. PROSES WARNA LINGKUNGAN
    vec4 base_color = texture(screen_texture, SCREEN_UV);
    float grayscale = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desaturated_color = mix(vec3(grayscale), base_color.rgb, saturation);
    vec3 mood_color = mix(desaturated_color, winter_color.rgb, winter_blend);
    
    vec2 uv = SCREEN_UV;
    uv.x *= 16.0;
    uv.y *= 9.0;
    
    float snow = 0.0;
    
    // 2. PROSES SALJU
    for (float i = 1.0; i <= 3.0; i++) {
        vec2 grid_uv = uv;
        grid_uv *= (1.5 * i);
        
        grid_uv.y -= TIME * snow_speed * (0.5 * i);
        
        float col_id = floor(grid_uv.x);
        float row_id = floor(grid_uv.y);
        
        // Bikin ID sel yang bener-bener unik buat tiap kotak di grid
        vec2 cell_id = vec2(col_id, row_id) + vec2(i * 100.0);
        float cell_rand = random(cell_id);
        
        // Sway tetep pake cell_rand biar beda-beda tiap butir
        float sway = sin(TIME * sway_speed + (cell_rand * 10.0)) * wind_sway;
        grid_uv.x += sway * 0.1; 
        
        vec2 drop_pos = fract(grid_uv);
        
        // REVISI KUNCI: Offset X dan Y sekarang pake ID unik, ditambah angka sembarang 
        // biar sumbu X dan Y dapet hasil acak yang beda jauh.
        float rand_x = random(cell_id + vec2(1.23, 4.56));
        float rand_y = random(cell_id + vec2(7.89, 1.23));
        
        // Kali 0.8 biar jarak ngacaknya makin luas, jadi bener-bener ga ada yang sejajar
        drop_pos.x += (rand_x - 0.5) * 0.8;
        drop_pos.y += (rand_y - 0.5) * 0.8;
        
        float dist = length(drop_pos - vec2(0.5));
        float current_snow = smoothstep(snow_size, snow_size * 0.1, dist);
        
        current_snow *= step(1.0 - snow_density, cell_rand);
        
        snow += current_snow;
    }
    
    snow = clamp(snow, 0.0, 1.0);
    
    // 3. GABUNGIN LINGKUNGAN + SALJU
    vec3 final_color = mix(mood_color, snow_color.rgb, snow * snow_color.a);
    COLOR = vec4(final_color, base_color.a);
}