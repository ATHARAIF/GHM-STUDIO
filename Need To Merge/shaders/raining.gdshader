shader_type canvas_item;

// Mengambil tekstur layar
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// ==========================================
// PARAMETER MENDUNG
// ==========================================
uniform vec4 overcast_color : source_color = vec4(0.2, 0.25, 0.35, 1.0);
uniform float overcast_blend : hint_range(0.0, 1.0) = 0.6;
uniform float saturation : hint_range(0.0, 1.0) = 0.4;

// ==========================================
// PARAMETER HUJAN
// ==========================================
uniform float rain_speed : hint_range(0.1, 10.0) = 4.0;
uniform float rain_density : hint_range(0.0, 1.0) = 0.35;
uniform float rain_angle : hint_range(-1.0, 1.0) = 0.2;
uniform vec4 rain_color : source_color = vec4(0.8, 0.9, 1.0, 0.5);

// KONTROL UKURAN PARTIKEL
uniform float rain_width : hint_range(0.001, 0.1) = 0.02;
uniform float rain_length : hint_range(0.01, 1.0) = 0.15;
uniform float rain_scale : hint_range(0.1, 5.0) = 1.0;

// ==========================================
// PARAMETER KILAT / PETIR
// ==========================================
uniform float lightning_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float lightning_chance : hint_range(0.0, 1.0) = 0.1;
uniform vec4 lightning_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);

// Fungsi Random 2D
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // 1. PROSES WARNA MENDUNG
    vec4 base_color = texture(screen_texture, SCREEN_UV);
    float grayscale = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desaturated_color = mix(vec3(grayscale), base_color.rgb, saturation);
    vec3 mood_color = mix(desaturated_color, overcast_color.rgb, overcast_blend);
    
    // 2. EFEK KILAT PETIR (FLASH)
    float time_tick = floor(TIME * lightning_frequency);
    float tick_rand = random(vec2(time_tick, 42.0)); 
    
    float is_lightning = step(1.0 - lightning_chance, tick_rand);
    
    float time_fract = fract(TIME * lightning_frequency);
    float flicker = max(0.0, sin(time_fract * 40.0)) * exp(-time_fract * 10.0);
    float lightning_flash = is_lightning * flicker;
    
    mood_color = mix(mood_color, lightning_color.rgb, lightning_flash * lightning_color.a);
    
    // 3. PROSES HUJAN
    vec2 uv = SCREEN_UV;
    uv.x += uv.y * rain_angle;
    
    float drop = 0.0;
    
    for (float i = 1.0; i <= 3.0; i++) {
        vec2 grid_uv = uv;
        
        grid_uv.x = (grid_uv.x + i * 0.432) * 100.0 / rain_scale; 
        grid_uv.y = grid_uv.y * 10.0 * i / rain_scale;
        
        // REVISI: Semua pengali kecepatan acak per-layer dan per-kolom udah dibuang.
        // Sekarang sumbu Y dikurangi dengan kecepatan yang rata di semua ukuran grid.
        grid_uv.y -= TIME * rain_speed * (10.0 * i / rain_scale);
        
        float col_id = floor(grid_uv.x);
        float row_id = floor(grid_uv.y);
        float cell_rand = random(vec2(col_id, row_id + i));
        
        vec2 drop_pos = fract(grid_uv);
        drop_pos.x += (cell_rand - 0.5) * 0.5; 
        
        float current_drop = step(1.0 - rain_width, drop_pos.x) * step(1.0 - rain_length, drop_pos.y);
        
        current_drop *= step(1.0 - rain_density, cell_rand);
        
        drop += current_drop;
    }
    
    drop = clamp(drop, 0.0, 1.0);
    
    // 4. GABUNGIN SEMUANYA
    vec3 final_color = mix(mood_color, rain_color.rgb, drop * rain_color.a);
    COLOR = vec4(final_color, base_color.a);
}