shader_type canvas_item;

uniform float temp = 37.0;

void fragment() {
	float blur_alpha_hot = 1.0 - ((44.0 - clamp(temp, 39.0, 44.0)) / 5.0);
	float blur_alpha_cold = (35.0 - clamp(temp, 24.0, 35.0)) / 11.0;

	vec4 cm_hot = texture(TEXTURE, UV);
	cm_hot.r = blur_alpha_hot;
	cm_hot.g = 0.0;
	cm_hot.b = 0.0;
	cm_hot.a = blur_alpha_hot;
	vec4 cm_cold = texture(TEXTURE, UV);
	cm_cold.r = blur_alpha_cold;
	cm_cold.g = 0.0;
	cm_cold.b = blur_alpha_cold;
	cm_cold.a = blur_alpha_cold;


	COLOR = cm_hot + cm_cold;
}
