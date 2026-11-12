class_name AvatarCharacter
extends Puppet
## Avatar del estudiante armado por piezas (RF-31). Tiñe cada pieza con los colores elegidos y le
## da vida con el motor de títeres: respira, parpadea, sigue el dedo con la mirada, trota, salta
## con voltereta, saluda, celebra con estrellas en los ojos, aplaude, baila y tropieza; la cola de
## caballo, las trenzas, la falda y los brazos rebotan solos. No conoce casos de uso ni datos.
##
## El origen está entre los pies; el personaje mide HEIGHT unidades hacia arriba.

const RIG := preload("res://scenes/characters/avatar/avatar_rig.tscn")
const HEIGHT := 386.0
const HAIR_STYLES := 6

const SKIN_PARTS: Array[String] = ["LegL", "LegR", "Torso/Neck", "Torso/ArmL/HandL", "Torso/ArmR/HandR", "Torso/Head/HeadArt"]
const TOP_PARTS: Array[String] = ["Torso/TorsoArt", "Torso/ArmL/SleeveL", "Torso/ArmR/SleeveR"]
const BOTTOM_PARTS: Array[String] = ["Pants", "Skirt"]
const HAIR_PARTS: Array[String] = ["Torso/Head/BrowL", "Torso/Head/BrowR", "HairBack/HairTail4",
	"Torso/Head/HairFront/BraidL3/BraidL3Art", "Torso/Head/HairFront/BraidR3/BraidR3Art"]
## Piezas de color propio: se ocultan en la silueta.
const DETAIL_PARTS: Array[String] = [
	"Torso/Band", "Torso/Head/Blush", "Torso/Head/Eyes", "Torso/Head/BrowL", "Torso/Head/BrowR", "Torso/Head/Mouth",
]
const BRAIDS: Array[String] = ["Torso/Head/HairFront/BraidL3", "Torso/Head/HairFront/BraidR3"]
const BRAID_TIES: Array[String] = ["Torso/Head/HairFront/BraidL3/BraidTieL3", "Torso/Head/HairFront/BraidR3/BraidTieR3"]
const LASH_EYES: Array[StringName] = [&"open", &"wide", &"star"]

const EXPRESSIONS := {
	&"neutral": {"eyes": &"open", "mouth": &"smile"},
	&"happy": {"eyes": &"happy", "mouth": &"smile", "brows": 4.0},
	&"joy": {"eyes": &"happy", "mouth": &"open", "brows": 6.0},
	&"laugh": {"eyes": &"happy", "mouth": &"open", "brows": 9.0},
	&"cheer": {"eyes": &"star", "mouth": &"open", "brows": 8.0, "blink": false},
	&"proud": {"eyes": &"happy", "mouth": &"grin", "brows": 5.0},
	&"wow": {"eyes": &"wide", "mouth": &"o", "brows": 13.0},
	&"think": {"eyes": &"open", "mouth": &"smile", "brows": 7.0, "tilt": -0.07, "mouth_scale": 0.7},
	&"worry": {"eyes": &"wide", "mouth": &"o", "brows": 5.0, "tilt": 0.32, "mouth_scale": 0.8},
	&"sad": {"eyes": &"open", "mouth": &"smile", "brows": -2.0, "tilt": 0.34, "mouth_scale": Vector2(0.85, -0.85),
		"eyes_scale": Vector2(1.0, 0.9)},
	&"ouch": {"eyes": &"squeeze", "mouth": &"grin", "brows": -5.0, "tilt": 0.18, "blink": false},
	&"dizzy": {"eyes": &"squeeze", "mouth": &"o", "brows": 4.0, "tilt": 0.26, "blink": false},
	&"determined": {"eyes": &"open", "mouth": &"grin", "brows": -5.0, "tilt": -0.28, "eyes_scale": Vector2(1.0, 0.88)},
	&"sleepy": {"eyes": &"closed", "mouth": &"smile", "brows": -3.0, "blink": false},
}

const CLIPS := {
	# Saluda con la mano derecha.
	&"wave": {"group": &"arms", "mute": [&"arm_r"], "tracks": {
		"arm_r:rot": [[0.22, -2.55, "back"], [0.38, -2.2], [0.54, -2.7], [0.7, -2.2], [0.86, -2.7], [1.02, -2.2],
			[1.18, -2.7], [1.48, 0.0, "back"]],
		"torso:rot": [[0.22, -0.03], [1.18, -0.03], [1.48, 0.0]],
		"look": [[0.2, [0.0, -0.2]], [1.2, [0.0, -0.2]], [1.5, [0.0, 0.0]]],
		"face": [[0.0, "joy"], [1.4, ""]],
	}},
	# Brazos arriba, estrellas en los ojos y un salto.
	&"celebrate": {"group": &"body", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.24, 2.6, "back"], [1.14, 2.6], [1.5, 0.0, "back"]],
		"arm_r:rot": [[0.24, -2.6, "back"], [1.14, -2.6], [1.5, 0.0, "back"]],
		"squash": [[0.08, [1.12, 0.86]], [0.18, [0.93, 1.1], "out"], [0.48, [1.0, 1.0]]],
		"lift": [[0.08, 0.0], [0.3, 48.0, "out"], [0.48, 0.0, "in"], [0.62, 0.0], [0.78, 22.0, "out"], [0.92, 0.0, "in"]],
		"face": [[0.0, "cheer"], [1.45, ""]],
		"emote": [[0.3, "sparkle"]],
	}, "length": 1.55},
	# Vuela en un salto grande: los brazos arriba hasta caer.
	&"airborne": {"group": &"body", "mute": [&"body", &"arm_l", &"arm_r", &"leg_l", &"leg_r", &"shoe_l", &"shoe_r"], "tracks": {
		"arm_l:rot": [[0.16, 2.5, "back"], [0.74, 2.5], [1.0, 0.0]],
		"arm_r:rot": [[0.16, -2.5, "back"], [0.74, -2.5], [1.0, 0.0]],
		"leg_l:sy": [[0.2, 0.8, "out"], [0.6, 0.8], [0.74, 1.0]],
		"shoe_l:y": [[0.2, -44.0, "out"], [0.6, -44.0], [0.74, 0.0]],
		"face": [[0.0, "joy"], [0.95, ""]],
	}, "length": 1.0},
	# Tropieza: se va de bruces con los brazos al aire y queda mareado un momento.
	&"stumble": {"group": &"body", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"lean": [[0.12, 0.42, "out"], [0.34, 0.42], [0.79, 0.0, "elastic"]],
		"arm_l:rot": [[0.12, 1.4, "out"], [0.34, 1.6], [0.7, 0.0]],
		"arm_r:rot": [[0.12, -1.4, "out"], [0.34, -1.6], [0.7, 0.0]],
		"squash": [[0.12, [1.06, 0.94]], [0.6, [1.0, 1.0], "elastic"]],
		"face": [[0.0, "ouch"], [0.5, "dizzy"], [0.95, ""]],
		"emote": [[0.3, "sweat"]],
	}, "length": 1.0},
	# Se asusta: saltito hacia atrás con los brazos arriba.
	&"startle": {"group": &"body", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"lean": [[0.1, -0.25, "out"], [0.45, -0.25], [0.85, 0.0, "elastic"]],
		"arm_l:rot": [[0.12, 2.2, "back"], [0.47, 2.2], [0.77, 0.0]],
		"arm_r:rot": [[0.12, -2.2, "back"], [0.47, -2.2], [0.77, 0.0]],
		"squash": [[0.06, [0.9, 1.12], "out"], [0.36, [1.0, 1.0]]],
		"lift": [[0.2, 20.0, "out"], [0.36, 0.0, "in"]],
		"face": [[0.0, "wow"], [0.85, ""]],
		"emote": [[0.02, "alert"]],
	}, "length": 0.9},
	# Aplaude delante del pecho.
	&"clap": {"group": &"arms", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.14, -1.0, "out"], [0.24, -0.72], [0.34, -1.0], [0.44, -0.72], [0.54, -1.0], [0.64, -0.72],
			[0.74, -1.0], [1.0, 0.0, "back"]],
		"arm_r:rot": [[0.14, 1.0, "out"], [0.24, 0.72], [0.34, 1.0], [0.44, 0.72], [0.54, 1.0], [0.64, 0.72],
			[0.74, 1.0], [1.0, 0.0, "back"]],
		"lift": [[0.24, 5.0], [0.34, 0.0], [0.44, 5.0], [0.54, 0.0], [0.64, 5.0], [0.74, 0.0]],
		"face": [[0.0, "joy"], [0.95, ""]],
	}},
	# Bailecito de la victoria: se mece con los brazos en vaivén.
	&"dance": {"group": &"body", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"lean": [[0.18, 0.1], [0.42, -0.1], [0.66, 0.1], [0.9, -0.1], [1.14, 0.08], [1.4, 0.0]],
		"lift": [[0.18, 10.0, "out"], [0.3, 0.0, "in"], [0.42, 10.0, "out"], [0.54, 0.0, "in"], [0.66, 10.0, "out"],
			[0.78, 0.0, "in"], [0.9, 10.0, "out"], [1.02, 0.0, "in"], [1.14, 8.0, "out"], [1.26, 0.0, "in"]],
		"arm_l:rot": [[0.18, 1.5, "out"], [0.42, 0.5], [0.66, 1.5], [0.9, 0.5], [1.14, 1.5], [1.4, 0.0]],
		"arm_r:rot": [[0.18, -0.5, "out"], [0.42, -1.5], [0.66, -0.5], [0.9, -1.5], [1.14, -0.5], [1.4, 0.0]],
		"head:rot": [[0.18, -0.08], [0.42, 0.08], [0.66, -0.08], [0.9, 0.08], [1.14, -0.06], [1.4, 0.0]],
		"face": [[0.0, "joy"], [1.35, ""]],
		"emote": [[0.2, "note"]],
	}},
	# Piensa con la mano en el mentón.
	&"think": {"group": &"arms", "mute": [&"arm_r"], "tracks": {
		"arm_r:rot": [[0.3, -2.35, "back"], [1.5, -2.35], [1.8, 0.0]],
		"head:rot": [[0.3, 0.07], [1.5, 0.07], [1.8, 0.0]],
		"look": [[0.3, [-0.5, -0.8]], [1.5, [-0.5, -0.8]], [1.8, [0.0, 0.0]]],
		"face": [[0.0, "think"], [1.75, ""]],
	}},
	# Se desinfla, triste, y se repone.
	&"sad": {"group": &"body", "tracks": {
		"squash": [[0.4, [1.04, 0.95], "out"], [1.2, [1.04, 0.95]], [1.6, [1.0, 1.0]]],
		"head:rot": [[0.4, 0.06], [1.2, 0.06], [1.6, 0.0]],
		"look": [[0.4, [0.0, 0.9]], [1.2, [0.0, 0.9]], [1.6, [0.0, 0.0]]],
		"face": [[0.0, "sad"], [1.55, ""]],
	}},
	# Cambia el peso de un pie al otro (reposo).
	&"shift_weight": {"group": &"body", "tracks": {
		"lean": [[0.5, 0.035], [1.4, 0.035], [1.9, -0.03], [2.8, -0.03], [3.3, 0.0]],
		"shift": [[0.5, [5.0, 0.0]], [1.4, [5.0, 0.0]], [1.9, [-4.0, 0.0]], [2.8, [-4.0, 0.0]], [3.3, [0.0, 0.0]]],
	}},
}

## Corre en su lugar mientras el mundo pasa: rebote, brazos y cuerpo inclinado. 0 está quieto.
var run_speed := 0.0:
	set(value):
		run_speed = value
		set_cycle(&"run", value)

var _avatar_look: AvatarLookViewModel
var _leap: Tween
var _lashes: CanvasItem


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"torso": "Torso", &"head": "Torso/Head", &"arm_l": "Torso/ArmL", &"arm_r": "Torso/ArmR",
		&"leg_l": "LegL", &"leg_r": "LegR", &"shoe_l": "ShoeL", &"shoe_r": "ShoeR", &"skirt": "Skirt",
		&"hair_front": "Torso/Head/HairFront", &"blush": "Torso/Head/Blush",
		&"brow_l": "Torso/Head/BrowL", &"brow_r": "Torso/Head/BrowR",
		&"tail": "HairBack/HairTail4", &"braid_l": BRAIDS[0], &"braid_r": BRAIDS[1],
	})
	# El cabello de atrás sigue a la cabeza aunque se dibuja detrás del cuerpo.
	var follow := RemoteTransform2D.new()
	follow.name = "HairBackFollow"
	_rig.get_node("Torso/Head").add_child(follow)
	follow.remote_path = follow.get_path_to(_rig.get_node("HairBack"))

	shadow_radius = 64.0
	shadow_flat = 0.22
	hit_rect = Rect2(-90.0, -HEIGHT, 180.0, HEIGHT + 10.0)
	body_center = Vector2(0.0, -HEIGHT * 0.5)
	emote_anchor = Vector2(82.0, -HEIGHT + 6.0)
	emote_size = 1.25
	look_range = Vector2(13.0, 9.0)
	look_turn = 0.03
	look_reach = 420.0

	_breathe(&"torso", 0.012, 2.2)
	_sway(&"head", "rot", 0.03, 1.1)
	_sway(&"arm_l", "rot", 0.04, 2.2, 0.6)
	_sway(&"arm_r", "rot", -0.04, 2.2, 0.6)

	_strip(&"tail", Vector2.ZERO, Vector2(112.0, 208.0), 8, {"wave": 0.1, "speed": 2.0, "curl": 1.0})
	_spring(&"tail", Vector2(112.0, 208.0), 236.0, {"stiffness": 105.0, "damping": 6.0, "limit": 0.9, "drag": 0.05})
	_spring(&"braid_l", Vector2.DOWN, 170.0, {"stiffness": 120.0, "damping": 5.5, "limit": 0.65, "drag": 0.04})
	_spring(&"braid_r", Vector2.DOWN, 170.0, {"stiffness": 132.0, "damping": 5.5, "limit": 0.65, "drag": 0.04})
	_spring(&"arm_l", Vector2.DOWN, 130.0, {"stiffness": 230.0, "damping": 12.0, "limit": 0.28, "drag": 0.006})
	_spring(&"arm_r", Vector2.DOWN, 130.0, {"stiffness": 230.0, "damping": 12.0, "limit": 0.28, "drag": 0.006})
	_spring(&"skirt", Vector2.DOWN, 110.0, {"stiffness": 190.0, "damping": 9.0, "limit": 0.13, "drag": 0.01})

	_face_setup(^"Torso/Head", EXPRESSIONS, {"talk": [&"open", &"smile", &"o"], "blinkable": [&"open", &"wide"]})
	_lashes = face.extras.get(&"lashes")
	face.extras.erase(&"lashes")
	face.changed = _update_lashes
	_look_layer(&"eyes", Vector2(1.0, 1.0))
	_look_layer(&"brow_l", Vector2(0.9, 0.85))
	_look_layer(&"brow_r", Vector2(0.9, 0.85))
	_look_layer(&"mouth", Vector2(1.1, 0.95))
	_look_layer(&"blush", Vector2(0.8, 0.75))
	_look_layer(&"hair_front", Vector2(0.22, 0.18))
	_look_layer(&"head", Vector2(0.45, 0.35))

	_cycle(&"run", {"stride": 0.38, "rate": Vector2(0.5, 2.2), "gain": Vector2(0.5, 1.5), "travel": 300.0, "tracks": [
		["lift", 10.0, 0.0, &"abs"],
		["squash_x", -0.035, 0.0, &"abs", 1.0, 0.035],
		["squash_y", 0.035, 0.0, &"abs", 1.0, -0.035],
		["lean", 0.0, 0.0, &"sin", 1.0, 0.07],
		["shift_x", 3.0],
		["torso:rot", 0.03],
		["arm_l:rot", 0.75],
		["arm_r:rot", 0.75],
		["head:rot", 0.04, 0.0, &"cos", 2.0],
		["head:y", 4.0, 0.6, &"abs"],
		# Trote de frente: cada rodilla sube hacia la cámara (la pierna se acorta y el pie sube).
		["leg_l:sy", -0.3, 0.0, &"half"],
		["shoe_l:y", -64.0, 0.0, &"half"],
		["leg_r:sy", -0.3, PI, &"half"],
		["shoe_r:y", -64.0, PI, &"half"],
	]})

	_clip_set(CLIPS)
	fidgets = [&"look_around", &"shift_weight", &"stretch", &"shift_weight", &"ponder"]
	fidget_wait = Vector2(6.0, 12.0)
	tap_reactions = [&"wave", &"laugh", &"clap", &"flip", &"dance"]
	if _avatar_look:
		apply(_avatar_look)


## Viste al personaje con su aspecto. Se puede llamar antes o después de entrar al árbol.
func apply(look: AvatarLookViewModel) -> void:
	_avatar_look = look
	if _rig == null:
		return
	for path in SKIN_PARTS:
		_tint(path, look.skin)
	for path in TOP_PARTS:
		_tint(path, look.top)
	for path in BOTTOM_PARTS:
		_tint(path, look.bottom)
	for path in HAIR_PARTS:
		_tint(path, look.hair)
	for style in HAIR_STYLES:
		var back := _rig.get_node("HairBack/HairBack%d" % style) as CanvasItem
		var front := _rig.get_node("Torso/Head/HairFront/HairFront%d" % style) as CanvasItem
		back.visible = style == look.hair_style
		front.visible = style == look.hair_style
		back.self_modulate = look.hair
		front.self_modulate = look.hair
	(_rig.get_node("HairBack/HairTail4") as CanvasItem).visible = look.hair_style == 4
	_rig.get_node("HairBack/HairTie4").visible = look.hair_style == 4 and not look.silhouette
	for path in BRAIDS:
		(_rig.get_node(path) as CanvasItem).visible = look.hair_style == 3
	for path in BRAID_TIES:
		(_rig.get_node(path) as CanvasItem).visible = not look.silhouette
	_rig.get_node("Pants").visible = not look.is_girl
	_rig.get_node("Skirt").visible = look.is_girl
	_rig.get_node("Socks").visible = look.is_girl and not look.silhouette
	for path in DETAIL_PARTS:
		(_rig.get_node(path) as CanvasItem).visible = not look.silhouette
	var shoe_tint := look.skin if look.silhouette else Color.WHITE
	_tint("ShoeL", shoe_tint)
	_tint("ShoeR", shoe_tint)
	_update_lashes()
	settle()
	refresh()


func look_model() -> AvatarLookViewModel:
	return _avatar_look


## Saluda con la mano derecha.
func wave() -> void:
	play(&"wave")


## Brazos arriba, ojos felices y un salto.
func celebrate() -> void:
	play(&"celebrate")


## Niega con la cabeza, sin perder la sonrisa (PIN incorrecto).
func shake_head() -> void:
	play(&"shake")


## Gran salto al acertar: se agacha, sale disparado (con una vuelta si `turn`), los brazos arriba
## y cae aplastándose.
func leap(leap_height: float = 110.0, turn: bool = false) -> void:
	if _leap:
		_leap.kill()
	if _hop:
		_hop.kill()
	play(&"airborne")
	Sounds.play(&"hop", 1.0, -5.0)
	spin = 0.0
	_leap = create_tween()
	_leap.tween_property(self, "squash", Vector2(1.18, 0.8), 0.09)
	_leap.tween_method(_leap_step.bind(leap_height, turn), 0.0, 1.0, 0.62)
	_leap.tween_callback(func() -> void:
		spin = 0.0
		lift = 0.0
		squash = Vector2.ONE)


func _leap_step(t: float, leap_height: float, turn: bool) -> void:
	lift = 4.0 * t * (1.0 - t) * leap_height
	spin = smoothstep(0.1, 0.85, t) * TAU if turn else 0.0
	var stretch := 1.0 - absf(t - 0.5) * 2.0
	squash = Vector2(0.9, 1.12).lerp(Vector2.ONE, stretch)


## Tropieza: se va hacia adelante, cierra los ojos y se recupera.
func stumble() -> void:
	play(&"stumble")


## Se asusta: da un saltito hacia atrás con los brazos arriba.
func startle() -> void:
	play(&"startle")


func react_to_petting() -> void:
	play(&"laugh")
	emote(&"heart")


func _tint(path: String, color: Color) -> void:
	(_rig.get_node(path) as CanvasItem).self_modulate = color


## Las pestañas solo se ven con los ojos abiertos.
func _update_lashes() -> void:
	if _lashes and _avatar_look:
		_lashes.visible = _avatar_look.is_girl and face.current_eyes in LASH_EYES
