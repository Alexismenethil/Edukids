shader_type canvas_item;
// Cielo del mundo: degradado vertical en coordenadas del mundo y un sol con halo.

uniform sampler2D gradient : source_color, filter_linear, repeat_disable;
// Rectángulo que cubre este nodo, en coordenadas del mundo (x, y, ancho, alto).
uniform vec4 rect = vec4(0.0, 0.0, 1280.0, 800.0);
uniform float y_top = -300.0;
uniform float y_bottom = 640.0;
// Sol: x como fracción del ancho visible, y en el mundo.
uniform vec2 sun = vec2(0.8, 380.0);
uniform float sun_radius = 46.0;
uniform vec4 sun_color : source_color = vec4(1.0, 0.98, 0.9, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);

void fragment() {
	vec2 v = rect.xy + UV * rect.zw;
	float t = clamp((v.y - y_top) / (y_bottom - y_top), 0.0, 1.0);
	vec3 color = texture(gradient, vec2(t, 0.5)).rgb;
	vec2 center = vec2(rect.x + sun.x * rect.z, sun.y);
	float d = length(v - center);
	float halo = exp(-d / (sun_radius * 5.0)) * 0.55 + exp(-d / (sun_radius * 1.6)) * 0.45;
	color = 1.0 - (1.0 - color) * (1.0 - glow_color.rgb * halo);
	float disc = smoothstep(sun_radius + 1.5, sun_radius - 1.5, d);
	color = mix(color, sun_color.rgb, disc);
	COLOR = vec4(color, 1.0);
}
