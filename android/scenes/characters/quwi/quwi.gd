class_name QuwiCharacter
extends Puppet
## Quwi, el cuy guía de la Sierra. Respira, parpadea, sigue el dedo con la mirada, mueve las orejas
## y la chalina con rebote, habla, salta, saluda y cambia de expresión. Si lo tocan, reacciona; si
## lo acarician, se pone feliz; y si lo dejan solo, se entretiene. Solo anima: las reglas del juego
## viven en el dominio.

const RIG := preload("res://scenes/characters/quwi/quwi_rig.tscn")
const SQUEAK_SOUND := preload("res://assets/audio/sfx/sfx_quwi_squeak.ogg")

const EXPRESSIONS := {
	&"neutral": {"eyes": &"open", "mouth": &"smile"},
	&"joy": {"eyes": &"open", "mouth": &"smile"},
	&"happy": {"eyes": &"happy", "mouth": &"smile", "brows": 4.0},
	&"cheer": {"eyes": &"happy", "mouth": &"open", "brows": 7.0},
	&"laugh": {"eyes": &"happy", "mouth": &"open", "brows": 9.0},
	&"pride": {"eyes": &"happy", "mouth": &"smile", "brows": 6.0},
	&"proud": {"eyes": &"happy", "mouth": &"smile", "brows": 6.0},
	&"comfort": {"eyes": &"happy", "mouth": &"smile", "brows": 2.0, "tilt": 0.12},
	&"think": {"eyes": &"open", "mouth": &"smile", "brows": 9.0, "tilt": -0.06, "mouth_scale": 0.8},
	&"surprise": {"eyes": &"open", "mouth": &"o", "brows": 16.0, "eyes_scale": 1.14},
	&"wow": {"eyes": &"open", "mouth": &"o", "brows": 16.0, "eyes_scale": 1.14},
	&"worry": {"eyes": &"open", "mouth": &"o", "brows": 6.0, "tilt": 0.3, "mouth_scale": 0.75},
	&"sad": {"eyes": &"open", "mouth": &"smile", "brows": -2.0, "tilt": 0.34, "mouth_scale": Vector2(0.9, -0.9),
		"eyes_scale": Vector2(1.0, 0.92)},
	&"ouch": {"eyes": &"squeeze", "mouth": &"o", "brows": -4.0, "tilt": 0.2, "blink": false},
	&"dizzy": {"eyes": &"squeeze", "mouth": &"o", "brows": 4.0, "tilt": 0.25, "blink": false},
	&"sleepy": {"eyes": &"closed", "mouth": &"smile", "brows": -3.0, "blink": false},
	&"determined": {"eyes": &"open", "mouth": &"smile", "brows": -3.0, "tilt": -0.26, "eyes_scale": Vector2(1.0, 0.9)},
}

const CLIPS := {
	# Saluda con la mano derecha, delante de la cara.
	&"wave": {"group": &"arms", "tracks": {
		"arm_r:rot": [[0.22, -1.9, "back"], [0.37, -1.45], [0.52, -2.1], [0.67, -1.45], [0.82, -2.1], [0.97, -1.45],
			[1.12, -2.1], [1.42, 0.0, "back"]],
		"head:rot": [[0.22, 0.07], [1.12, 0.07], [1.42, 0.0]],
		"cue": [[0.0, "arm_r_front"], [1.4, "arms_back"]],
		"face": [[0.0, "happy"], [1.3, ""]],
	}},
	# Levanta los dos brazos de alegría.
	&"arms_up": {"group": &"arms", "tracks": {
		"arm_r:rot": [[0.22, -1.55, "back"], [0.72, -1.55], [1.02, 0.0]],
		"arm_l:rot": [[0.22, 1.55, "back"], [0.72, 1.55], [1.02, 0.0]],
		"cue": [[0.0, "arms_front"], [1.0, "arms_back"]],
	}},
	# Celebración: brazos arriba, ojos felices y dos saltos con las orejas al vuelo.
	&"celebrate": {"group": &"body", "tracks": {
		"squash": [[0.08, [1.14, 0.84]], [0.18, [0.92, 1.1], "out"], [0.5, [1.0, 1.0]],
			[0.66, [1.1, 0.88]], [0.76, [0.94, 1.08], "out"], [1.06, [1.0, 1.0]]],
		"lift": [[0.08, 0.0], [0.32, 44.0, "out"], [0.52, 0.0, "in"], [0.66, 0.0], [0.86, 30.0, "out"], [1.04, 0.0, "in"]],
		"lean": [[0.32, -0.06], [0.52, 0.0], [0.86, 0.06], [1.04, 0.0]],
		"arm_r:rot": [[0.2, -1.6, "back"], [1.1, -1.6], [1.4, 0.0]],
		"arm_l:rot": [[0.2, 1.6, "back"], [1.1, 1.6], [1.4, 0.0]],
		"cue": [[0.0, "arms_front"], [1.38, "arms_back"]],
		"face": [[0.0, "cheer"], [1.9, ""]],
	}, "length": 2.0},
	# Se sacude una oreja.
	&"ear_twitch": {"group": &"ears", "tracks": {
		"ear_l:rot": [[0.07, -0.26, "out"], [0.16, 0.08], [0.24, -0.2], [0.5, 0.0, "elastic"]],
	}},
	# Olfatea el aire con la nariz.
	&"sniff": {"group": &"head", "tracks": {
		"head:y": [[0.1, -5.0, "out"], [0.2, -2.0], [0.3, -6.0], [0.4, -2.0], [0.5, -6.0], [0.75, 0.0]],
		"look": [[0.15, [0.3, -0.7]], [0.55, [0.3, -0.7]], [0.8, [0.0, 0.0]]],
		"mouth:sy": [[0.1, 0.8], [0.2, 1.0], [0.3, 0.8], [0.4, 1.0], [0.5, 0.8], [0.6, 1.0]],
	}},
	# Cosquillas: se retuerce de risa.
	&"tickle": {"group": &"body", "tracks": {
		"lift": [[0.07, 8.0, "out"], [0.14, 0.0, "in"], [0.21, 8.0, "out"], [0.28, 0.0, "in"], [0.35, 8.0, "out"],
			[0.42, 0.0, "in"], [0.49, 6.0, "out"], [0.56, 0.0, "in"]],
		"lean": [[0.1, 0.09], [0.24, -0.09], [0.38, 0.08], [0.52, -0.06], [0.7, 0.0]],
		"arm_r:rot": [[0.1, -0.7, "out"], [0.6, -0.7], [0.85, 0.0]],
		"arm_l:rot": [[0.1, 0.7, "out"], [0.6, 0.7], [0.85, 0.0]],
		"face": [[0.0, "laugh"], [0.95, ""]],
	}, "length": 1.0},
	# Se asoma hacia la cámara, curioso.
	&"peek": {"group": &"body", "tracks": {
		"squash": [[0.25, [1.06, 1.06], "back"], [0.9, [1.06, 1.06]], [1.2, [1.0, 1.0]]],
		"head:rot": [[0.25, -0.12, "back"], [0.9, -0.12], [1.2, 0.0]],
		"face": [[0.0, "wow"], [0.5, "happy"], [1.2, ""]],
	}},
}

var _voice: SfxPlayer
var _mood: StringName = &"joy"
var _tilt := 0.0
var _tilt_goal := 0.0
var _head: PuppetBone


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"torso": "Torso", &"head": "Torso/Head", &"ear_l": "Torso/Head/EarL", &"ear_r": "Torso/Head/EarR",
		&"arm_l": "Torso/ArmL", &"arm_r": "Torso/ArmR", &"scarf": "Torso/Scarf",
		&"scarf_tail": "Torso/ScarfTail", &"foot_l": "FootL", &"foot_r": "FootR",
	})
	for brow: String in ["Brows", "BrowL", "BrowR"]:
		if _rig.has_node("Torso/Head/" + brow):
			_add_bone(StringName(brow.to_snake_case()), _rig.get_node("Torso/Head/" + brow))
	_head = get_bone(&"head")
	shadow_radius = 78.0
	shadow_flat = 0.14
	hit_rect = Rect2(-100.0, -295.0, 200.0, 305.0)
	body_center = Vector2(0.0, -130.0)
	emote_anchor = Vector2(86.0, -288.0)
	emote_size = 1.15
	look_range = Vector2(7.0, 5.0)
	look_turn = 0.035
	look_reach = 380.0

	_breathe(&"torso", 0.02, 2.4)
	_sway(&"head", "rot", 0.035, 1.3)
	_sway(&"ear_l", "rot", 0.05, 2.1, 0.6)
	_sway(&"ear_r", "rot", -0.05, 2.1)
	_sway(&"arm_l", "rot", 0.03, 2.4, 0.8)
	_sway(&"arm_r", "rot", -0.03, 2.4, 0.8)

	_spring(&"ear_l", Vector2(-0.6, -0.8), 34.0, {"stiffness": 210.0, "damping": 9.0, "limit": 0.5})
	_spring(&"ear_r", Vector2(0.6, -0.8), 34.0, {"stiffness": 210.0, "damping": 9.0, "limit": 0.5})
	_strip(&"scarf_tail", Vector2(0.0, 0.0), Vector2(-6.0, 62.0), 7, {"wave": 0.2, "speed": 2.2, "curl": 1.3})
	_spring(&"scarf_tail", Vector2(-0.1, 1.0), 62.0, {"stiffness": 120.0, "damping": 6.5, "limit": 0.75, "drag": 0.05})

	_face_setup(^"Torso/Head", EXPRESSIONS, {"talk": [&"open", &"smile", &"o"]})
	_look_layer(&"eyes", Vector2(1.0, 1.0))
	_look_layer(&"brows", Vector2(0.9, 0.8))
	_look_layer(&"brow_l", Vector2(0.9, 0.8))
	_look_layer(&"brow_r", Vector2(0.9, 0.8))
	_look_layer(&"mouth", Vector2(1.1, 0.9))
	_look_layer(&"head", Vector2(0.55, 0.45))
	_look_layer(&"ear_l", Vector2(-0.5, -0.2))
	_look_layer(&"ear_r", Vector2(-0.5, -0.2))

	_clip_set(CLIPS)
	fidgets = [&"look_around", &"ear_twitch", &"sniff", &"ear_twitch", &"ponder", &"stretch", &"wiggle"]
	fidget_wait = Vector2(4.5, 9.0)
	tap_reactions = [&"celebrate", &"wave", &"tickle", &"startle", &"flip", &"peek"]

	_voice = SfxPlayer.new()
	_voice.name = "Voice"
	_voice.voices = 3
	add_child(_voice)
	set_expression(_mood)


func _animate(delta: float) -> void:
	_tilt = lerpf(_tilt, _tilt_goal, minf(1.0, delta * 6.0))
	if _head:
		_head.rotation += _tilt
		if face.talking:
			_head.position.y += 2.0 * sin(_time * 13.0)


func _on_cue(cue_name: StringName) -> void:
	match cue_name:
		&"arm_r_front":
			get_bone(&"arm_r").node.z_index = 1
		&"arms_front":
			get_bone(&"arm_r").node.z_index = 1
			get_bone(&"arm_l").node.z_index = 1
		&"arms_back":
			get_bone(&"arm_r").node.z_index = 0
			get_bone(&"arm_l").node.z_index = 0
	super(cue_name)


## Cambia la expresión: joy, cheer, think, surprise, pride o comfort.
func set_mood(mood: StringName) -> void:
	_mood = mood
	set_expression(mood)
	look_reset()
	_tilt_goal = 0.0
	match mood:
		&"surprise":
			hop(26.0)
		&"think":
			_tilt_goal = 0.1
			look_toward(Vector2(0.55, -0.8))
		&"cheer", &"pride":
			_tilt_goal = -0.05
			arms_up()
		&"comfort":
			_tilt_goal = 0.08


## El «wiik, wiik» de un cuy contento.
func squeak() -> void:
	_voice.play(SQUEAK_SOUND, randf_range(0.95, 1.12))


## Reacción al tocarlo: celebra, saluda, se ríe, se asusta, da una voltereta o se asoma.
func react_to_tap() -> void:
	squeak()
	super()


func react_to_petting() -> void:
	squeak()
	play(&"tickle")
	emote(&"heart")


## Saluda con la mano derecha, delante de la cara.
func wave() -> void:
	play(&"wave")


## Levanta los dos brazos de alegría.
func arms_up() -> void:
	play(&"arms_up")


## Celebración: ojos felices, brazos arriba y dos saltitos.
func celebrate() -> void:
	play(&"celebrate")


## Entra saltando desde un costado hasta su lugar.
func enter_from(offset_x: float, hops: int = 3) -> void:
	var target := position.x
	position.x += offset_x
	settle()
	look_toward(Vector2(-signf(offset_x), 0.0), 0.5 * hops)
	var tween := create_tween()
	for i in hops:
		tween.tween_callback(hop.bind(30.0))
		tween.tween_property(self, "position:x", target + offset_x * (1.0 - float(i + 1) / hops), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.2)
	tween.tween_callback(wave)
