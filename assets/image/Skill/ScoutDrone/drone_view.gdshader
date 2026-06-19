shader_type canvas_item;

uniform float noise_amount : hint_range(0.0, 1.0) = 0.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float scanline = step(0.5, fract(uv.y * 300.0)) * 0.08;
	float n = rand(uv * (TIME * 10.0 + 1.0));
	float static_noise = (n - 0.5) * noise_amount;
	vec3 col = vec3(scanline + static_noise);
	float alpha = scanline + abs(static_noise) * 1.5;
	COLOR = vec4(col, clamp(alpha, 0.0, 0.9));
}
