class_name SisaCharacter
extends Puppet
## Mama Sisa, la guardiana del quipu. Abuela sabia y cálida: respira tranquila, sus trenzas, su
## pollera y su sombrero se mecen, saluda, presenta el quipu, se asusta cuando Atoq lo jala,
## asiente y despide a los viajeros. Solo anima: las reglas del juego viven en el dominio.

const RIG := preload("res://scenes/characters/sisa/sisa_rig.tscn")
const HEIGHT := 398.0

const EXPRESSIONS := {
	&"neutral": {"eyes": &"open", "mouth": &"smile"},
	&"happy": {"eyes": &"happy", "mouth": &"smile", "brows": 3.0},
	&"joy": {"eyes": &"happy", "mouth": &"open", "brows": 5.0},
	&"laugh": {"eyes": &"happy", "mouth": &"open", "brows": 7.0},
	&"proud": {"eyes": &"happy", "mouth": &"smile", "brows": 4.0},
	&"wow": {"eyes": &"wide", "mouth": &"o", "brows": 12.0},
	&"worry": {"eyes": &"wide", "mouth": &"o", "brows": 5.0, "tilt": 0.3, "mouth_scale": 0.8},
	&"sad": {"eyes": &"open", "mouth": &"smile", "brows": -1.0, "tilt": 0.32, "mouth_scale": Vector2(0.85, -0.85),
		"eyes_scale": Vector2(1.0, 0.9)},
	&"think": {"eyes": &"open", "mouth": &"smile", "brows": 6.0, "tilt": -0.05, "mouth_scale": 0.75},
	&"determined": {"eyes": &"open", "mouth": &"smile", "brows": -3.0, "tilt": -0.2},
	&"ouch": {"eyes": &"closed", "mouth": &"o", "tilt": 0.2, "blink": false},
	&"dizzy": {"eyes": &"closed", "mouth": &"o", "tilt": 0.2, "blink": false},
	&"sleepy": {"eyes": &"closed", "mouth": &"smile", "blink": false},
}

const CLIPS := {
	# Saluda con la mano, sin prisa.
	&"wave": {"group": &"arms", "mute": [&"arm_r"], "tracks": {
		"arm_r:rot": [[0.3, -2.3, "back"], [0.52, -2.0], [0.74, -2.45], [0.96, -2.0], [1.18, -2.45], [1.6, 0.0, "inout"]],
		"head:rot": [[0.3, 0.05], [1.2, 0.05], [1.6, 0.0]],
		"face": [[0.0, "happy"], [1.5, ""]],
	}},
	# Abre los brazos para mostrar el quipu.
	&"present": {"group": &"arms", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.35, 0.85, "back"], [1.5, 0.85], [1.9, 0.0]],
		"arm_r:rot": [[0.35, -0.85, "back"], [1.5, -0.85], [1.9, 0.0]],
		"squash": [[0.35, [0.98, 1.03], "out"], [1.5, [0.98, 1.03]], [1.9, [1.0, 1.0]]],
		"face": [[0.0, "joy"], [1.8, ""]],
	}},
	# Se asusta: los brazos al aire y un pasito atrás.
	&"gasp": {"group": &"body", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.14, 2.3, "back"], [0.9, 2.2], [1.3, 0.0]],
		"arm_r:rot": [[0.14, -2.3, "back"], [0.9, -2.2], [1.3, 0.0]],
		"lean": [[0.12, -0.12, "out"], [0.9, -0.08], [1.3, 0.0, "elastic"]],
		"lift": [[0.14, 12.0, "out"], [0.28, 0.0, "in"]],
		"face": [[0.0, "wow"], [1.3, ""]],
		"emote": [[0.02, "alert"]],
	}, "length": 1.4},
	# Entrega algo con las dos manos hacia adelante.
	&"give": {"group": &"arms", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.4, -0.5, "inout"], [1.4, -0.5], [1.8, 0.0]],
		"arm_r:rot": [[0.4, -1.1, "inout"], [1.4, -1.1], [1.8, 0.0]],
		"lean": [[0.4, 0.07], [1.4, 0.07], [1.8, 0.0]],
		"face": [[0.0, "happy"], [1.8, ""]],
	}},
	# Aplaude despacito, orgullosa.
	&"clap": {"group": &"arms", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.2, -0.95, "out"], [0.34, -0.7], [0.48, -0.95], [0.62, -0.7], [0.76, -0.95], [0.9, -0.7],
			[1.04, -0.95], [1.4, 0.0, "back"]],
		"arm_r:rot": [[0.2, 0.95, "out"], [0.34, 0.7], [0.48, 0.95], [0.62, 0.7], [0.76, 0.95], [0.9, 0.7],
			[1.04, 0.95], [1.4, 0.0, "back"]],
		"face": [[0.0, "joy"], [1.35, ""]],
	}},
	# Se lleva la mano al pecho, pensativa.
	&"reflect": {"group": &"arms", "mute": [&"arm_r"], "tracks": {
		"arm_r:rot": [[0.4, 0.9, "inout"], [1.6, 0.9], [2.0, 0.0]],
		"look": [[0.4, [0.0, 0.6]], [1.6, [0.0, 0.6]], [2.0, [0.0, 0.0]]],
		"face": [[0.0, "think"], [1.9, ""]],
	}},
}


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"torso": "Torso", &"head": "Torso/Head", &"arm_l": "Torso/ArmL", &"arm_r": "Torso/ArmR",
		&"skirt": "Skirt", &"braid_l": "Torso/Head/BraidL", &"braid_r": "Torso/Head/BraidR",
		&"hat": "Torso/Head/Hat", &"blush": "Torso/Head/Blush",
		&"brow_l": "Torso/Head/BrowL", &"brow_r": "Torso/Head/BrowR",
	})
	shadow_radius = 86.0
	shadow_flat = 0.17
	hit_rect = Rect2(-100.0, -HEIGHT, 200.0, HEIGHT + 10.0)
	body_center = Vector2(0.0, -HEIGHT * 0.5)
	emote_anchor = Vector2(104.0, -HEIGHT + 30.0)
	emote_size = 1.25
	look_range = Vector2(12.0, 8.0)
	look_turn = 0.025
	look_reach = 430.0

	_breathe(&"torso", 0.011, 1.7)
	_sway(&"head", "rot", 0.025, 0.9)
	_sway(&"arm_l", "rot", 0.03, 1.7, 0.6)
	_sway(&"arm_r", "rot", -0.03, 1.7, 0.6)

	_spring(&"braid_l", Vector2.DOWN, 200.0, {"stiffness": 110.0, "damping": 5.5, "limit": 0.5, "drag": 0.04})
	_spring(&"braid_r", Vector2.DOWN, 200.0, {"stiffness": 122.0, "damping": 5.5, "limit": 0.5, "drag": 0.04})
	_spring(&"skirt", Vector2.DOWN, 220.0, {"stiffness": 170.0, "damping": 8.0, "limit": 0.09, "drag": 0.01})
	_spring(&"hat", Vector2.UP, 130.0, {"stiffness": 260.0, "damping": 10.0, "limit": 0.1, "drag": 0.0})
	_spring(&"arm_l", Vector2.DOWN, 130.0, {"stiffness": 230.0, "damping": 12.0, "limit": 0.22, "drag": 0.006})
	_spring(&"arm_r", Vector2.DOWN, 130.0, {"stiffness": 230.0, "damping": 12.0, "limit": 0.22, "drag": 0.006})

	_face_setup(^"Torso/Head", EXPRESSIONS, {"talk": [&"open", &"smile", &"o"], "blinkable": [&"open", &"wide"]})
	_look_layer(&"eyes", Vector2(1.0, 1.0))
	_look_layer(&"brow_l", Vector2(0.9, 0.85))
	_look_layer(&"brow_r", Vector2(0.9, 0.85))
	_look_layer(&"mouth", Vector2(1.1, 0.95))
	_look_layer(&"blush", Vector2(0.8, 0.75))
	_look_layer(&"hat", Vector2(0.3, 0.15))
	_look_layer(&"head", Vector2(0.4, 0.3))

	_cycle(&"walk", {"stride": 0.62, "rate": Vector2(0.5, 1.6), "gain": Vector2(0.6, 1.2), "travel": 120.0, "tracks": [
		["lift", 5.0, 0.0, &"abs"],
		["lean", 0.035],
		["shift_x", 3.0],
		["arm_l:rot", 0.22],
		["arm_r:rot", 0.22],
		["skirt:rot", 0.05],
	]})

	_clip_set(CLIPS)
	fidgets = [&"look_around", &"reflect", &"nod"]
	fidget_wait = Vector2(7.0, 13.0)
	tap_reactions = [&"wave", &"laugh", &"clap", &"nod"]


func react_to_petting() -> void:
	play(&"laugh")
	emote(&"heart")
