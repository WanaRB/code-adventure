shader_type canvas_item;

uniform float noise_amount : hint_range(0.0, 1.0) = 0.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// 1. Efek Tear/Robekan Horisontal
	// Menghasilkan garis horisontal acak yang membuat layar tampak tergeser
	float displacement = rand(vec2(uv.y * 10.0, TIME)) * noise_amount;
	float tear = step(0.8, rand(vec2(TIME, uv.y * 5.0))) * displacement;
	vec2 distorted_uv = uv + vec2(tear, 0.0);

	// 2. Static Noise Agresif
	// Menggunakan UV yang terdistorsi dan melipatgandakan kecepatan serta intensitas pengali
	float n = rand(distorted_uv * (TIME * 20.0 + 1.0));
	float static_noise = (n - 0.5) * (noise_amount * 3.0);

	// 3. Scanline Dinamis
	// Frekuensi garis menurun (menebal) dan opasitasnya meningkat seiring jarak
	float scanline_freq = 300.0 - (noise_amount * 150.0);
	float scanline = step(0.5, fract(uv.y * scanline_freq)) * (0.05 + noise_amount * 0.3);

	// 4. Kalkulasi Warna dan Opasitas
	vec3 col = vec3(scanline + static_noise);
	
	// Alpha dikalikan kuat dengan noise_amount agar layar benar-benar jernih di jarak 0
	// dan memblokir layar hingga 95% pekat saat mendekati batas maksimal
	float alpha = (abs(static_noise) + scanline + abs(tear)) * noise_amount * 2.5;

	COLOR = vec4(col, clamp(alpha, 0.0, 0.95));
}