shader_type canvas_item;

// Mengambil tangkapan gambar dari layar game lu
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Mengatur seberapa ngeblok warnanya. Makin kecil angkanya, makin kartun.
uniform float color_depth : hint_range(1.0, 255.0) = 8.0;

void fragment() {
    // Membaca warna asli dari setiap pixel di layar
    vec4 original_color = texture(screen_texture, SCREEN_UV);

    // Membatasi gradasi warna biar jadi efek kartun/posterize
    vec3 c = original_color.rgb;
    c = round(c * color_depth) / color_depth;

    // Menampilkan hasil filter ke layar
    COLOR = vec4(c, original_color.a);
}