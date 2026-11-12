class_name PuppetMoves
extends RefCounted
## Biblioteca de gestos que sirven para cualquier títere: solo mueven el cuerpo entero (salto,
## inclinación, aplastamiento, giro) y la mirada, así que funcionan sin importar qué piezas tenga
## el personaje. Un personaje puede definir un clip con el mismo nombre para reemplazar el de aquí.
##
## Las expresiones que nombran (happy, joy, wow, think, sad, worry, ouch, dizzy, proud, laugh) son
## el vocabulario común: si el personaje no tiene alguna, se queda con la cara que tenía.

const LIBRARY := {
	# Saltito de alegría.
	&"hop": {"group": &"body", "tracks": {
		"squash": [[0.08, [1.12, 0.86]], [0.18, [0.93, 1.09], "out"], [0.44, [1.0, 1.0]]],
		"lift": [[0.08, 0.0], [0.28, 36.0, "out"], [0.46, 0.0, "in"]],
	}},
	# Dos saltos seguidos con la cara feliz.
	&"cheer": {"group": &"body", "tracks": {
		"squash": [[0.08, [1.14, 0.84]], [0.18, [0.92, 1.1], "out"], [0.46, [1.0, 1.0]],
			[0.56, [1.1, 0.88]], [0.66, [0.94, 1.08], "out"], [0.9, [1.0, 1.0]]],
		"lift": [[0.08, 0.0], [0.3, 46.0, "out"], [0.48, 0.0, "in"], [0.56, 0.0], [0.74, 30.0, "out"], [0.9, 0.0, "in"]],
		"lean": [[0.3, -0.05], [0.48, 0.0], [0.74, 0.05], [0.9, 0.0]],
		"face": [[0.0, "joy"], [1.25, ""]],
	}, "length": 1.3},
	# Voltereta en el aire.
	&"flip": {"group": &"body", "mute": [&"body"], "tracks": {
		"squash": [[0.09, [1.18, 0.8]], [0.2, [0.9, 1.12], "out"], [0.62, [1.0, 1.0]]],
		"lift": [[0.09, 0.0], [0.4, 118.0, "out"], [0.71, 0.0, "in"]],
		"spin": [[0.15, 0.0], [0.62, TAU, "inout"], [0.63, 0.0, "hold"]],
		"face": [[0.0, "joy"], [1.0, ""]],
	}, "length": 1.0},
	# Dice que sí con la cabeza.
	&"nod": {"group": &"head", "tracks": {
		"look": [[0.12, [0.0, 0.9]], [0.26, [0.0, -0.3]], [0.4, [0.0, 0.8]], [0.58, [0.0, 0.0]]],
		"squash": [[0.12, [1.02, 0.97]], [0.26, [1.0, 1.0]], [0.4, [1.02, 0.98]], [0.58, [1.0, 1.0]]],
	}},
	# Dice que no con la cabeza.
	&"shake": {"group": &"head", "tracks": {
		"look": [[0.1, [-1.0, 0.0]], [0.24, [1.0, 0.0]], [0.38, [-0.9, 0.0]], [0.52, [0.8, 0.0]], [0.68, [0.0, 0.0]]],
		"lean": [[0.1, -0.03], [0.24, 0.03], [0.38, -0.03], [0.52, 0.02], [0.68, 0.0]],
	}},
	# Se asusta: brinco hacia atrás.
	&"startle": {"group": &"body", "tracks": {
		"squash": [[0.06, [0.88, 1.14], "out"], [0.3, [1.0, 1.0]]],
		"lift": [[0.14, 20.0, "out"], [0.3, 0.0, "in"]],
		"lean": [[0.1, -0.2, "out"], [0.5, -0.12], [0.9, 0.0, "elastic"]],
		"shift": [[0.12, [-14.0, 0.0], "out"], [0.9, [0.0, 0.0]]],
		"face": [[0.0, "wow"], [0.9, ""]],
		"emote": [[0.02, "alert"]],
	}, "length": 1.0},
	# Recibe un golpe o un susto fuerte: se encoge con los ojos apretados.
	&"flinch": {"group": &"body", "tracks": {
		"squash": [[0.07, [1.2, 0.78], "out"], [0.3, [1.12, 0.86]], [0.7, [1.0, 1.0], "elastic"]],
		"lean": [[0.07, -0.12], [0.7, 0.0, "elastic"]],
		"face": [[0.0, "ouch"], [0.75, ""]],
	}, "length": 0.8},
	# Tiembla de miedo o de frío.
	&"shiver": {"group": &"body", "tracks": {
		"shift": [[0.05, [-4.0, 0.0]], [0.1, [4.0, 0.0]], [0.15, [-4.0, 0.0]], [0.2, [4.0, 0.0]], [0.25, [-3.0, 0.0]],
			[0.3, [3.0, 0.0]], [0.35, [-3.0, 0.0]], [0.4, [3.0, 0.0]], [0.5, [0.0, 0.0]]],
		"squash": [[0.1, [0.96, 1.04]], [0.5, [1.0, 1.0]]],
		"face": [[0.0, "worry"], [0.9, ""]],
	}, "length": 0.9},
	# Bailecito: se mece de lado a lado.
	&"wiggle": {"group": &"body", "tracks": {
		"lean": [[0.14, 0.1], [0.34, -0.1], [0.54, 0.09], [0.74, -0.08], [0.94, 0.0]],
		"lift": [[0.14, 8.0, "out"], [0.24, 0.0, "in"], [0.34, 8.0, "out"], [0.44, 0.0, "in"], [0.54, 8.0, "out"],
			[0.64, 0.0, "in"], [0.74, 6.0, "out"], [0.84, 0.0, "in"]],
		"face": [[0.0, "happy"], [0.95, ""]],
	}},
	# Se ríe: rebotes cortos y rápidos.
	&"laugh": {"group": &"body", "tracks": {
		"lift": [[0.07, 7.0, "out"], [0.14, 0.0, "in"], [0.21, 7.0, "out"], [0.28, 0.0, "in"], [0.35, 7.0, "out"],
			[0.42, 0.0, "in"], [0.49, 6.0, "out"], [0.56, 0.0, "in"], [0.63, 5.0, "out"], [0.7, 0.0, "in"]],
		"lean": [[0.1, -0.08, "out"], [0.7, -0.06], [0.95, 0.0]],
		"face": [[0.0, "laugh"], [0.95, ""]],
	}, "length": 1.0},
	# Se queda mareado.
	&"dizzy": {"group": &"body", "tracks": {
		"lean": [[0.2, 0.1], [0.5, -0.1], [0.8, 0.08], [1.1, -0.06], [1.4, 0.0]],
		"shift": [[0.2, [6.0, 0.0]], [0.5, [-6.0, 0.0]], [0.8, [5.0, 0.0]], [1.1, [-3.0, 0.0]], [1.4, [0.0, 0.0]]],
		"face": [[0.0, "dizzy"], [1.5, ""]],
		"emote": [[0.0, "dizzy"]],
	}, "length": 1.6},
	# Saca pecho, orgulloso.
	&"proud": {"group": &"body", "tracks": {
		"squash": [[0.2, [0.95, 1.07], "back"], [0.9, [0.95, 1.07]], [1.2, [1.0, 1.0]]],
		"lean": [[0.2, -0.06, "out"], [0.9, -0.06], [1.2, 0.0]],
		"look": [[0.2, [0.0, -0.5]], [0.9, [0.0, -0.5]], [1.2, [0.0, 0.0]]],
		"face": [[0.0, "proud"], [1.2, ""]],
	}},
	# Suspira y se desinfla un poco.
	&"sigh": {"group": &"body", "tracks": {
		"squash": [[0.3, [0.98, 1.04]], [0.9, [1.05, 0.94], "out"], [1.5, [1.0, 1.0]]],
		"look": [[0.5, [0.0, 0.7]], [1.2, [0.0, 0.7]], [1.6, [0.0, 0.0]]],
		"face": [[0.0, "sad"], [1.6, ""]],
	}},
	# Mira a un lado y al otro, con curiosidad.
	&"look_around": {"group": &"head", "tracks": {
		"look": [[0.25, [-0.9, -0.1], "out"], [0.85, [-0.9, -0.1]], [1.2, [0.9, -0.2], "inout"], [1.8, [0.9, -0.2]],
			[2.1, [0.0, 0.0]]],
	}},
	# Ladea la cabeza, pensando.
	&"ponder": {"group": &"head", "tracks": {
		"look": [[0.3, [0.5, -0.8], "out"], [1.3, [0.5, -0.8]], [1.6, [0.0, 0.0]]],
		"lean": [[0.3, 0.04], [1.3, 0.04], [1.6, 0.0]],
		"face": [[0.0, "think"], [1.6, ""]],
	}},
	# Se estira hacia arriba y se relaja.
	&"stretch": {"group": &"body", "tracks": {
		"squash": [[0.5, [0.93, 1.1], "inout"], [1.0, [0.93, 1.1]], [1.3, [1.06, 0.95], "out"], [1.7, [1.0, 1.0], "elastic"]],
		"look": [[0.5, [0.0, -0.9]], [1.0, [0.0, -0.9]], [1.4, [0.0, 0.0]]],
		"face": [[0.3, "sleepy"], [1.1, "happy"], [1.7, ""]],
	}},
}

static var _compiled: Dictionary = {}


static func get_clip(clip_name: StringName) -> PuppetClip:
	if _compiled.has(clip_name):
		return _compiled[clip_name]
	if not LIBRARY.has(clip_name):
		return null
	var clip := PuppetClip.from_dict(clip_name, LIBRARY[clip_name])
	_compiled[clip_name] = clip
	return clip


static func names() -> Array[StringName]:
	var list: Array[StringName] = []
	list.assign(LIBRARY.keys())
	return list
