shader_type canvas_item;
render_mode blend_add;
// Rayos de sol suaves que salen del sol y respiran despacio.

uniform vec4 rect = vec4(0.0, 0.0, 1280.0, 800.0);
uniform vec2 sun = vec2(0.8, 380.0);
uniform float intensity = 0.16;
uniform vec4 tint : source_color = vec4(1.0, 0.88, 0.62, 1.0);
uniform float reach = 900.0;

void fragment() {
	vec2 v = rect.xy + UV * rect.zw;
	vec2 d = v - vec2(rect.x + sun.x * rect.z, sun.y);
	float angle = atan(d.y, d.x);
	float beams = sin(angle * 9.0 + TIME * 0.12) * 0.5 + 0.5;
	beams *= sin(angle * 5.0 - TIME * 0.08 + 1.7) * 0.5 + 0.5;
	beams = smoothstep(0.25, 0.85, beams);
	float fade = exp(-length(d) / reach);
	float below = smoothstep(-80.0, 160.0, d.y);
	float breathe = 0.85 + 0.15 * sin(TIME * 0.6);
	COLOR = vec4(tint.rgb * beams * fade * below * intensity * breathe, 1.0);
}
