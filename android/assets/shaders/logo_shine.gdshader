shader_type canvas_item;
// Destello diagonal que recorre las letras del logotipo.
// shine_x es la posición de la franja en coordenadas del lienzo; la mueve la pantalla de inicio.

uniform float shine_x = -10000.0;
uniform float width = 30.0;
uniform float strength = 0.6;

varying vec2 canvas_position;

void vertex() {
	canvas_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// En Godot 4, COLOR ya trae el color de la textura multiplicado por el de los vértices.
	vec4 color = COLOR;
	float distance_to_band = abs((canvas_position.x - canvas_position.y * 0.4) - shine_x);
	float band = 1.0 - smoothstep(0.0, width, distance_to_band);
	// El contorno oscuro casi no brilla: así la letra conserva su forma.
	float light = smoothstep(0.18, 0.5, dot(color.rgb, vec3(0.299, 0.587, 0.114)));
	color.rgb = mix(color.rgb, vec3(1.0, 0.99, 0.94), band * strength * light);
	COLOR = color;
}
