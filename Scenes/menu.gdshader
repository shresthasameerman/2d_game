shader_type canvas_item;

// Declare the screen texture
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float blur_size : hint_range(0.0, 10.0) = 5.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 sum = vec4(0.0);

    // 3x3 blur
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 offset = vec2(x, y) * blur_size * SCREEN_PIXEL_SIZE;
            sum += texture(SCREEN_TEXTURE, uv + offset);
        }
    }

    COLOR = sum / 9.0;
}
