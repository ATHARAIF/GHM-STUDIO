shader_type canvas_item;

// Ambil tekstur tanaman lo
uniform sampler2D original_texture;

// Parameter buat ngatur goyangannya (bisa diotak-atik di Inspector)
uniform float speed : hint_range(0.0, 5.0) = 2.0;       // Kecepatan goyang
uniform float strength : hint_range(0.0, 0.5) = 0.05;  // Jarak goyang (kiri-kanan)
uniform float complexity : hint_range(0.0, 10.0) = 4.0; // Kerumitan gelombang

void fragment() {
    // Ambil kordinat UV asli
    vec2 uv = UV;
    
    // Bikin titik tumpu (pivot) di bawah tanaman (biar bawahnya diem, atasnya goyang)
    // Asumsi texture tanaman lo berdiri vertikal, dan akar ada di UV.y = 1.0
    float pivot_factor = 1.0 - uv.y; // Semakin ke atas (y=0), semakin besar faktornya
    
    // Hitung distorsi pake fungsi sine wave buat efek goyang
    // TIME adalah variable bawaan Godot buat waktu
    float distortion = sin(TIME * speed + uv.y * complexity) * strength * pivot_factor;
    
    // Geser kordinat UV.x berdasarkan hasil distorsi
    uv.x += distortion;
    
    // Output warna pake kordinat UV yang udah digoyang
    COLOR = texture(original_texture, uv);
}