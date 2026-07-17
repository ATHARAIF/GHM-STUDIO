shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Parameter buat ngatur seberapa cepet warnanya muter
uniform float rgb_speed : hint_range(0.1, 5.0) = 0.5;

// Variasi acak dari script MultiMesh biar RGB tiap tanaman gak seragam amat
instance uniform float phase_offset = 0.0;

// Fungsi sakti buat ngubah spektrum warna (HSV) jadi RGB yang dimengerti monitor
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // Bikin nilai Hue (warna) jalan terus ngikutin waktu (TIME)
    // Ditambah phase_offset biar tiap instance di MultiMesh warnanya beda dikit
    float hue = fract((TIME * rgb_speed) + (phase_offset * 0.1));
    
    // Konversi Hue ke RGB. Saturation dan Value diset 1.0 biar warnanya medok dan terang
    vec3 final_color = hsv2rgb(vec3(hue, 1.0, 1.0));
    
    // Terapin warnanya ke objek
    ALBEDO = final_color;
    
    // (Opsional) Bikin tanamannya seolah-olah mancarin cahaya sendiri
    EMISSION = final_color * 0.8; 
}