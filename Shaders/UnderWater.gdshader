shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 1.0) = 0.1;
uniform float frequency : hint_range(0.0, 10.0) = 1.0;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform vec4 Shader_color : source_color;


void fragment() {
    // Get the screen dimensions from the SCREEN_TEXTURE's size
    vec2 screen_size = vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);

    // Calculate the UV coordinate relative to the screen dimensions
    vec2 uv = FRAGCOORD.xy / screen_size;

    // Calculate the offset for the displacement effect
    float offset = sin(uv.y * frequency + TIME * speed) * amplitude;

    // Apply the offset to the UV coordinate and sample the texture
    vec4 color = texture(TEXTURE, uv + vec2(0.0, offset));
	color.rgba = Shader_color.rgba;

    // Set the fragment color output
    COLOR = color;
}