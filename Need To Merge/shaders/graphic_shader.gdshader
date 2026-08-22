shader_type canvas_item;

// Mengambil tekstur layar di belakang ColorRect
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Parameter yang bisa diotak-atik di Inspector
uniform vec4 warm_color : source_color = vec4(1.0, 0.85, 0.5, 1.0); // Warna kuning/oranye
uniform float tint_amount : hint_range(0.0, 1.0) = 0.35; // Ketebalan filter
uniform float contrast : hint_range(0.0, 2.0) = 1.15; // Kontras layar

void fragment() {
    // Ambil warna asli dari elemen-elemen game di layar
    vec4 original_color = texture(screen_texture, SCREEN_UV);
    vec3 color = original_color.rgb;

    // Tambahin kontras biar warnanya nggak pudar
    color = (color - 0.5) * contrast + 0.5;

    // Campur warna asli layar sama warna warm/kekuningan
    vec3 blended_color = mix(color, warm_color.rgb, tint_amount);

    // Kasih sedikit boost brightness buat nambahin efek terik matahari musim panas
    blended_color *= 1.05;

    // Output hasil akhirnya
    COLOR = vec4(blended_color, original_color.a);
}