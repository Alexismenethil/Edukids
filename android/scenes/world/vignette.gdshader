shader_type canvas_item;
// Viñeta suave y cálida en las esquinas: enfoca la mirada al centro de la escena.

uniform float strength = 0.28;
uniform vec4 tint : source_color = vec4(0.22, 0.12, 0.16, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 1.35;
	float edge = smoothstep(0.42, 0.95, length(uv));
	COLOR = vec4(tint.rgb, edge * strength);
}
