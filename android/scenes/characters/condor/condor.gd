class_name CondorCharacter
extends Puppet
## Kuntur, el cóndor andino. Bate las alas con todo el cuerpo, planea, mira hacia donde va, cierra
## las garras para cargar al avatar y grazna orgulloso. El origen está entre sus garras, así lo que
## lleva colgando queda justo debajo. Solo anima: las reglas del juego viven en el dominio.

const RIG := preload("res://scenes/characters/condor/condor_rig.tscn")

const EXPRESSIONS := {
	&"neutral": {"eyes": &"open"},
	&"happy": {"eyes": &"happy", "blink": false},
	&"joy": {"eyes": &"happy", "blink": false},
	&"laugh": {"eyes": &"happy", "blink": false},
	&"proud": {"eyes": &"happy", "blink": false},
	&"determined": {"eyes": &"angry", "blink": false},
	&"angry": {"eyes": &"angry", "blink": false},
	&"wow": {"eyes": &"open", "eyes_scale": 1.18},
	&"worry": {"eyes": &"open", "eyes_scale": 1.12},
	&"sleepy": {"eyes": &"closed", "blink": false},
	&"ouch": {"eyes": &"closed", "blink": false},
	&"dizzy": {"eyes": &"closed", "blink": false},
}

const CLIPS := {
	# Grazna al cielo con las alas bien abiertas.
	&"screech": {"group": &"head", "tracks": {
		"head:rot": [[0.2, -0.3, "back"], [0.8, -0.3], [1.1, 0.0]],
		"head:y": [[0.2, -10.0, "back"], [0.8, -10.0], [1.1, 0.0]],
		"wing_l:rot": [[0.2, 0.35, "back"], [0.8, 0.3], [1.1, 0.0]],
		"wing_r:rot": [[0.2, -0.35, "back"], [0.8, -0.3], [1.1, 0.0]],
		"face": [[0.0, "proud"], [1.1, ""]],
		"emote": [[0.25, "note"]],
	}},
	# Cierra las garras para agarrar algo.
	&"grab": {"group": &"feet", "tracks": {
		"foot_l:rot": [[0.12, 0.5, "out"], [0.3, -0.2, "back"], [0.6, 0.0]],
		"foot_r:rot": [[0.12, -0.5, "out"], [0.3, 0.2, "back"], [0.6, 0.0]],
		"squash": [[0.14, [1.06, 0.92]], [0.5, [1.0, 1.0], "elastic"]],
		"face": [[0.0, "determined"], [0.7, ""]],
	}},
	# Sacude las plumas.
	&"ruffle": {"group": &"body", "tracks": {
		"lean": [[0.08, 0.07], [0.16, -0.07], [0.24, 0.06], [0.32, -0.06], [0.4, 0.04], [0.55, 0.0]],
		"ruff:scale": [[0.2, [1.15, 1.15], "out"], [0.6, [1.0, 1.0], "elastic"]],
		"tail:rot": [[0.1, 0.2], [0.2, -0.2], [0.3, 0.2], [0.4, -0.15], [0.55, 0.0]],
		"face": [[0.0, "happy"], [0.6, ""]],
	}},
}

## Qué tanto bate las alas: 0 las deja quietas (planeo), 1 vuela, 2 aletea con fuerza.
var flap := 1.0:
	set(value):
		flap = value
		set_cycle(&"fly", value)
## De 0 a 1: alas recogidas hacia abajo (posado en el suelo).
var folded := 0.0

var _wing_l: PuppetBone
var _wing_r: PuppetBone
var _fold := 0.0


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"wing_l": "WingL", &"wing_r": "WingR", &"head": "Head", &"ruff": "Ruff", &"tail": "Tail",
		&"foot_l": "FootL", &"foot_r": "FootR", &"body": "BodyArt",
	})
	_wing_l = get_bone(&"wing_l")
	_wing_r = get_bone(&"wing_r")
	shadow_scale = 0.0
	grounded = false
	hit_rect = Rect2(-250.0, -250.0, 500.0, 260.0)
	body_center = Vector2(0.0, -100.0)
	emote_anchor = Vector2(70.0, -262.0)
	emote_size = 1.2
	look_range = Vector2(7.0, 5.0)
	look_turn = 0.05
	look_reach = 460.0

	_breathe(&"body", 0.012, 2.0)
	_sway(&"head", "rot", 0.03, 1.1)
	_sway(&"tail", "rot", 0.05, 1.3)
	_sway(&"wing_l", "rot", 0.03, 1.6)
	_sway(&"wing_r", "rot", -0.03, 1.6)

	_spring(&"head", Vector2.UP, 90.0, {"stiffness": 240.0, "damping": 11.0, "limit": 0.16, "drag": 0.004})
	_spring(&"tail", Vector2.DOWN, 110.0, {"stiffness": 150.0, "damping": 7.0, "limit": 0.4, "drag": 0.02})
	_spring(&"foot_l", Vector2.DOWN, 70.0, {"stiffness": 130.0, "damping": 6.0, "limit": 0.5, "drag": 0.02})
	_spring(&"foot_r", Vector2.DOWN, 70.0, {"stiffness": 140.0, "damping": 6.0, "limit": 0.5, "drag": 0.02})

	_face_setup(^"Head", EXPRESSIONS)
	_look_layer(&"eyes", Vector2(1.0, 1.0))
	_look_layer(&"head", Vector2(0.6, 0.5))

	# Aleteo: las alas bajan y el cuerpo sube; al subir las alas, se encogen un poco.
	_cycle(&"fly", {"stride": 0.62, "rate": Vector2(0.3, 2.2), "gain": Vector2(0.35, 1.25), "travel": 0.0, "tracks": [
		["wing_l:rot", 0.5],
		["wing_r:rot", -0.5],
		["wing_l:sx", -0.1, 0.0, &"half"],
		["wing_r:sx", -0.1, 0.0, &"half"],
		["lift", 12.0, PI, &"sin"],
		["head:y", 5.0, -0.6],
		["tail:rot", 0.08, 0.8],
		["squash_y", 0.025, PI],
	]})
	_clip_set(CLIPS)
	fidgets = [&"ruffle", &"look_around", &"screech"]
	fidget_wait = Vector2(6.0, 12.0)
	tap_reactions = [&"screech", &"ruffle", &"flip"]
	set_cycle(&"fly", flap)


func _animate(delta: float) -> void:
	_fold = lerpf(_fold, folded, minf(1.0, delta * 5.0))
	if _fold > 0.001:
		_wing_l.rotation -= 1.0 * _fold
		_wing_r.rotation += 1.0 * _fold
		_wing_l.scale.x *= 1.0 - 0.3 * _fold
		_wing_r.scale.x *= 1.0 - 0.3 * _fold


func react_to_petting() -> void:
	play(&"ruffle")
	emote(&"heart")
