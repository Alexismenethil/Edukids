shader_type canvas_item;
// Banda de neblina suave que se desplaza: bordes difusos arriba y abajo.

uniform sampler2D noise : filter_linear, repeat_enable;
uniform vec4 rect = vec4(0.0, 0.0, 1280.0, 100.0);
uniform float scroll = 0.0;
uniform vec4 color : source_color = vec4(1.0, 0.96, 0.9, 0.55);
uniform float scale = 0.0011;

void fragment() {
	vec2 v = rect.xy + UV * rect.zw;
	float n1 = texture(noise, vec2((v.x + scroll) * scale + TIME * 0.004, 0.31)).r;
	float n2 = texture(noise, vec2((v.x + scroll * 1.2) * scale * 2.3 - TIME * 0.006, 0.71)).r;
	float shape = smoothstep(0.0, 0.45, UV.y) * smoothstep(1.0, 0.6, UV.y);
	float wisps = clamp(0.45 + (n1 - 0.5) * 1.3 + (n2 - 0.5) * 0.7, 0.0, 1.0);
	COLOR = vec4(color.rgb, color.a * shape * wisps);
}
