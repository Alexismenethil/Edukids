class_name TunkiCharacter
extends GuideCharacter
## Tunki, el gallito de las rocas, guía de la Selva. Presumido pero noble: baila moviendo la
## cresta, aletea, infla el pecho y sacude la cola. Lo común de los guías está en GuideCharacter.
## Solo anima: las reglas del juego viven en el dominio.

const RIG := preload("res://scenes/characters/tunki/tunki_rig.tscn")

const OWN_CLIPS := {
	# Baile del gallito: se mece de lado a lado con la cresta al vuelo y las alas abiertas.
	&"dance": {"group": &"body", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"lean": [[0.16, 0.14], [0.38, -0.14], [0.6, 0.14], [0.82, -0.14], [1.04, 0.1], [1.3, 0.0]],
		"lift": [[0.16, 14.0, "out"], [0.27, 0.0, "in"], [0.38, 14.0, "out"], [0.49, 0.0, "in"], [0.6, 14.0, "out"],
			[0.71, 0.0, "in"], [0.82, 14.0, "out"], [0.93, 0.0, "in"], [1.04, 10.0, "out"], [1.15, 0.0, "in"]],
		"arm_l:rot": [[0.16, 1.2, "out"], [0.38, 0.5], [0.6, 1.2], [0.82, 0.5], [1.04, 1.2], [1.3, 0.0]],
		"arm_r:rot": [[0.16, -0.5, "out"], [0.38, -1.2], [0.6, -0.5], [0.82, -1.2], [1.04, -0.5], [1.3, 0.0]],
		"tail:rot": [[0.16, -0.3], [0.38, 0.3], [0.6, -0.3], [0.82, 0.3], [1.04, -0.2], [1.3, 0.0]],
		"face": [[0.0, "cheer"], [1.25, ""]],
		"emote": [[0.2, "note"]],
	}},
	# Aletea rápido, como para alzar vuelo.
	&"flutter": {"group": &"arms", "mute": [&"arm_l", &"arm_r"], "tracks": {
		"arm_l:rot": [[0.08, 1.3, "out"], [0.16, 0.5], [0.24, 1.3], [0.32, 0.5], [0.4, 1.3], [0.48, 0.5], [0.56, 1.3], [0.8, 0.0, "back"]],
		"arm_r:rot": [[0.08, -1.3, "out"], [0.16, -0.5], [0.24, -1.3], [0.32, -0.5], [0.4, -1.3], [0.48, -0.5], [0.56, -1.3], [0.8, 0.0, "back"]],
		"lift": [[0.3, 22.0, "out"], [0.6, 16.0], [0.8, 0.0, "in"]],
		"cue": [[0.0, "arms_front"], [0.78, "arms_back"]],
	}},
	# Presume: infla el pecho y levanta la cresta.
	&"show_off": {"group": &"body", "tracks": {
		"squash": [[0.25, [1.06, 1.06], "back"], [1.0, [1.06, 1.06]], [1.3, [1.0, 1.0]]],
		"crest:scale": [[0.25, [1.12, 1.16], "back"], [1.0, [1.12, 1.16]], [1.3, [1.0, 1.0], "elastic"]],
		"look": [[0.25, [0.0, -0.6]], [1.0, [0.0, -0.6]], [1.3, [0.0, 0.0]]],
		"face": [[0.0, "pride"], [1.3, ""]],
		"emote": [[0.3, "sparkle"]],
	}},
}


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"torso": "Torso", &"head": "Torso/Head", &"arm_l": "Torso/ArmL", &"arm_r": "Torso/ArmR",
		&"crest": "Torso/Head/Crest", &"tail": "Tail", &"foot_l": "FootL", &"foot_r": "FootR",
	})
	voice_pitch = 1.55
	shadow_radius = 78.0
	shadow_flat = 0.14
	hit_rect = Rect2(-100.0, -300.0, 200.0, 310.0)
	body_center = Vector2(0.0, -130.0)
	emote_anchor = Vector2(92.0, -292.0)
	emote_size = 1.15
	look_range = Vector2(7.0, 5.0)
	look_turn = 0.04
	look_reach = 380.0

	_breathe(&"torso", 0.02, 2.6)
	_sway(&"head", "rot", 0.04, 1.5)
	_sway(&"crest", "rot", 0.03, 2.2, 0.4)
	_sway(&"tail", "rot", 0.06, 1.9)
	_sway(&"arm_l", "rot", 0.03, 2.6, 0.8)
	_sway(&"arm_r", "rot", -0.03, 2.6, 0.8)

	_spring(&"crest", Vector2.UP, 200.0, {"stiffness": 150.0, "damping": 6.5, "limit": 0.3, "drag": 0.012})
	_spring(&"tail", Vector2.DOWN, 70.0, {"stiffness": 170.0, "damping": 7.0, "limit": 0.5, "drag": 0.02})
	_spring(&"arm_l", Vector2.DOWN, 150.0, {"stiffness": 220.0, "damping": 11.0, "limit": 0.22, "drag": 0.006})
	_spring(&"arm_r", Vector2.DOWN, 150.0, {"stiffness": 220.0, "damping": 11.0, "limit": 0.22, "drag": 0.006})

	_guide_setup(^"Torso/Head")
	_look_layer(&"crest", Vector2(0.75, 0.6))
	_clip_set(OWN_CLIPS)
	fidgets = [&"look_around", &"show_off", &"flutter", &"ponder", &"dance"]
	tap_reactions = [&"dance", &"wave", &"flutter", &"tickle", &"show_off", &"flip"]
