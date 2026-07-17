shader_type canvas_item;

// Ngambil layar di belakangnya
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Parameter yang bisa diatur di Inspector
uniform float curvature : hint_range(0.0, 10.0) = 3.5; // Tingkat kelengkungan layar
uniform float scanline_count : hint_range(0.0, 1000.0) = 450.0; // Jumlah garis TV
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.25; // Ketebalan garis
uniform float vignette_intensity : hint_range(0.0, 2.0) = 1.2; // Kegelapan di pojok layar

void fragment() {
    // Kordinat layar saat ini
    vec2 uv = SCREEN_UV;
    
    // 1. Efek Kelengkungan (Curvature)
    // Ubah kordinat dari (0 sampe 1) jadi (-1 sampe 1) buat nentuin titik tengah
    vec2 centered_uv = uv * 2.0 - 1.0;
    
    // Bikin pinggiran melengkung
    vec2 offset = centered_uv.yx / curvature;
    uv = uv + centered_uv * offset * offset;
    
    // Potong layar yang keluar dari frame (kasih warna hitam)
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        // Ambil warna asli pake kordinat yang udah melengkung
        vec4 color = texture(screen_texture, uv);
        
        // 2. Efek Garis-garis TV (Scanlines)
        // Pake fungsi matematika sin() buat bikin pola garis naik turun
        float scanline = sin(uv.y * scanline_count * 3.14159);
        scanline = (scanline * 0.5 + 0.5) * scanline_opacity; // Atur ketebalannya
        color.rgb -= scanline; // Kurangi terang warna asli dengan garis gelap
        
        // 3. Efek Pojokan Gelap (Vignette)
        // Hitung jarak dari titik tengah (0.5, 0.5)
        float dist = distance(uv, vec2(0.5, 0.5));
        // Bikin transisi halus dari terang ke gelap
        float vignette = smoothstep(0.8, vignette_intensity * 0.4, dist);
        color.rgb *= vignette;
        
        // Output hasil akhir
        COLOR = color;
    }
}