class_name HumbiCharacter
extends GuideCharacter
## Humbi, el pingüino de Humboldt, guía de la Costa. Tranquilo y observador: camina balanceándose,
## se desliza de panza, aletea, se acomoda el gorrito de pescador y saluda con la aleta. Lo común
## de los guías está en GuideCharacter. Solo anima: las reglas del juego viven en el dominio.

const RIG := preload("res://scenes/characters/humbi/humbi_rig.tscn")

const OWN_CLIPS := {
	# Se desliza de panza hacia adelante y se levanta.
	&"slide": {"group": &"body", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"lean": [[0.2, 1.35, "back"], [0.9, 1.35], [1.3, 0.0, "back"]],
		"lift": [[0.2, 30.0, "out"], [0.9, 30.0], [1.3, 0.0, "in"]],
		"shift": [[0.2, [20.0, 0.0]], [0.9, [70.0, 0.0], "out"], [1.3, [0.0, 0.0], "inout"]],
		"arm_l:rot": [[0.2, 1.4, "out"], [0.9, 1.4], [1.3, 0.0]],
		"arm_r:rot": [[0.2, -1.4, "out"], [0.9, -1.4], [1.3, 0.0]],
		"face": [[0.0, "cheer"], [1.25, ""]],
		"cue": [[0.25, "stomp"]],
	}},
	# Aletea contento.
	&"flap": {"group": &"arms", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.1, 0.9, "out"], [0.2, 0.2], [0.3, 0.9], [0.4, 0.2], [0.5, 0.9], [0.6, 0.2], [0.85, 0.0]],
		"arm_r:rot": [[0.1, -0.9, "out"], [0.2, -0.2], [0.3, -0.9], [0.4, -0.2], [0.5, -0.9], [0.6, -0.2], [0.85, 0.0]],
		"lift": [[0.2, 6.0], [0.3, 0.0], [0.4, 6.0], [0.5, 0.0]],
		"face": [[0.0, "happy"], [0.85, ""]],
	}},
	# Se acomoda el gorrito con una aleta.
	&"tip_hat": {"group": &"arms", "mute": [&"arm_r"], "tracks": {
		"arm_r:rot": [[0.3, -2.5, "back"], [0.9, -2.5], [1.3, 0.0]],
		"hat:rot": [[0.4, 0.18, "out"], [0.9, 0.18], [1.3, 0.0, "elastic"]],
		"head:rot": [[0.3, 0.06], [0.9, 0.06], [1.3, 0.0]],
		"cue": [[0.0, "arm_r_front"], [1.28, "arms_back"]],
		"face": [[0.0, "happy"], [1.3, ""]],
	}},
}


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"torso": "Torso", &"head": "Torso/Head", &"arm_l": "Torso/ArmL", &"arm_r": "Torso/ArmR",
		&"hat": "Torso/Head/Hat", &"foot_l": "FootL", &"foot_r": "FootR",
	})
	voice_pitch = 0.62
	shadow_radius = 78.0
	shadow_flat = 0.14
	hit_rect = Rect2(-100.0, -300.0, 200.0, 310.0)
	body_center = Vector2(0.0, -130.0)
	emote_anchor = Vector2(92.0, -292.0)
	emote_size = 1.15
	look_range = Vector2(7.0, 5.0)
	look_turn = 0.035
	look_reach = 380.0

	_breathe(&"torso", 0.018, 1.9)
	_sway(&"head", "rot", 0.03, 1.0)
	_sway(&"arm_l", "rot", 0.05, 1.9, 0.8)
	_sway(&"arm_r", "rot", -0.05, 1.9, 0.8)

	_spring(&"hat", Vector2.UP, 70.0, {"stiffness": 240.0, "damping": 9.0, "limit": 0.14, "drag": 0.0})
	_spring(&"arm_l", Vector2.DOWN, 150.0, {"stiffness": 200.0, "damping": 10.0, "limit": 0.3, "drag": 0.008})
	_spring(&"arm_r", Vector2.DOWN, 150.0, {"stiffness": 200.0, "damping": 10.0, "limit": 0.3, "drag": 0.008})

	_guide_setup(^"Torso/Head")
	_look_layer(&"hat", Vector2(0.4, 0.2))
	# Camina balanceándose de un pie al otro.
	_cycle(&"walk", {"stride": 0.52, "rate": Vector2(0.5, 1.8), "gain": Vector2(0.6, 1.2), "travel": 110.0, "tracks": [
		["lean", 0.11],
		["lift", 5.0, 0.0, &"abs"],
		["foot_l:rot", -0.3, 0.0, &"half"],
		["foot_r:rot", 0.3, PI, &"half"],
		["arm_l:rot", 0.2],
		["arm_r:rot", 0.2],
	]})
	_clip_set(OWN_CLIPS)
	fidgets = [&"look_around", &"tip_hat", &"flap", &"ponder"]
	tap_reactions = [&"flap", &"wave", &"slide", &"tickle", &"tip_hat", &"flip"]
