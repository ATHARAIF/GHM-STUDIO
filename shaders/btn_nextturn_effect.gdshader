shader_type canvas_item;

// 0: Radial, 1: Bottom to Top, 2: Left to Right, 3: Center Expand
// 4: Top to Bottom, 5: Right to Left, 6: Horizontal Split, 7: Vertical Split
uniform int fill_mode : hint_range(0, 7) = 0; 
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform vec2 button_size;

varying vec2 local_pos;

void vertex() {
    // Ambil posisi lokal pixel relatif terhadap ujung kiri atas tombol
    local_pos = VERTEX;
}

void fragment() {
    // Pusat tombol ada di setengah ukuran tombol
    vec2 center = button_size / 2.0;
    vec2 diff = local_pos - center;
    float fill_value = 0.0;
    
    if (fill_mode == 0) {
        // RADIAL (Clock-Wipe)
        float angle = atan(diff.y, diff.x) + 1.57079632679; 
        if (angle < 0.0) { angle += 6.28318530718; }
        fill_value = angle / 6.28318530718;
    } 
    else if (fill_mode == 1) {
        // BOTTOM TO TOP
        fill_value = 1.0 - (local_pos.y / button_size.y);
    }
    else if (fill_mode == 2) {
        // LEFT TO RIGHT
        fill_value = local_pos.x / button_size.x;
    }
    else if (fill_mode == 3) {
        // CENTER EXPAND
        float max_dist = length(center);
        float current_dist = length(diff);
        fill_value = current_dist / max_dist;
    }
    else if (fill_mode == 4) {
        // TOP TO BOTTOM
        fill_value = local_pos.y / button_size.y;
    }
    else if (fill_mode == 5) {
        // RIGHT TO LEFT
        fill_value = 1.0 - (local_pos.x / button_size.x);
    }
    else if (fill_mode == 6) {
        // HORIZONTAL SPLIT
        fill_value = abs(diff.x) / center.x;
    }
    else if (fill_mode == 7) {
        // VERTICAL SPLIT
        fill_value = abs(diff.y) / center.y;
    }

    float brightness = (COLOR.r + COLOR.g + COLOR.b) / 3.0;
    
    if (fill_value <= progress && brightness < 0.95) {
        COLOR.rgb = mix(COLOR.rgb, tint_color.rgb, tint_color.a);
    }
}
