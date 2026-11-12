shader_type canvas_item;
// Viento en el pasto del primer plano: las puntas (arriba) se mecen, la base (abajo) no.

uniform float amplitude = 4.0;
uniform float speed = 1.5;
uniform float waves = 5.0;

void fragment() {
	float bend = pow(clamp(1.0 - UV.y, 0.0, 1.0), 2.0);
	float wind = sin(TIME * speed + UV.x * waves * 6.2831853) * 0.65
		+ sin(TIME * speed * 1.73 + UV.x * waves * 2.0 * 6.2831853 + 1.1) * 0.35;
	vec2 uv = UV + vec2(wind * amplitude * TEXTURE_PIXEL_SIZE.x * bend, 0.0);
	COLOR = texture(TEXTURE, uv) * COLOR;
}
