shader_type canvas_item;
// Agua en estilo limpio: degradado del borde a lo hondo y líneas de corriente que se mueven.
// `flow` > 0 hace correr las líneas (río); cerca de 0 las deja casi quietas (laguna).

uniform vec4 rect = vec4(0.0, 0.0, 1280.0, 200.0);
uniform vec4 shallow : source_color = vec4(0.42, 0.80, 0.90, 1.0);
uniform vec4 deep : source_color = vec4(0.16, 0.52, 0.72, 1.0);
uniform vec4 foam : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flow = 60.0;
uniform float rows = 0.11;
uniform float depth_span = 160.0;
uniform float scroll = 0.0;
uniform float opacity = 1.0;

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 v = rect.xy + UV * rect.zw;
	float below = v.y - rect.y;
	float depth = clamp(below / depth_span, 0.0, 1.0);
	vec3 color = mix(shallow.rgb, deep.rgb, depth);
	float row = floor(v.y * rows);
	float seed = hash(row);
	float within = fract(v.y * rows);
	float x = v.x + scroll + TIME * flow * (0.6 + seed * 0.8);
	float streak = sin(x * (0.012 + seed * 0.02) + seed * 37.0 + sin(TIME * 0.7 + seed * 6.0) * 1.5);
	float band = smoothstep(0.40, 0.47, within) * smoothstep(0.62, 0.55, within);
	float lines = band * smoothstep(0.55, 0.72, streak);
	color = mix(color, foam.rgb, lines * 0.55 * (1.0 - depth * 0.6));
	float edge = smoothstep(7.0, 1.0, below);
	color = mix(color, foam.rgb, edge * 0.55);
	COLOR = vec4(color, opacity);
}
