class_name QuwiCharacter
extends GuideCharacter
## Quwi, el cuy guía de la Sierra. Respira, parpadea, sigue el dedo con la mirada, mueve las orejas
## y la chalina con rebote, habla, salta, saluda y cambia de expresión. Si lo tocan, reacciona; si
## lo acarician, se pone feliz; y si lo dejan solo, se entretiene. Lo común de los guías está en
## GuideCharacter. Solo anima: las reglas del juego viven en el dominio.

const RIG := preload("res://scenes/characters/quwi/quwi_rig.tscn")

const OWN_CLIPS := {
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
}


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"torso": "Torso", &"head": "Torso/Head", &"ear_l": "Torso/Head/EarL", &"ear_r": "Torso/Head/EarR",
		&"arm_l": "Torso/ArmL", &"arm_r": "Torso/ArmR", &"scarf": "Torso/Scarf",
		&"scarf_tail": "Torso/ScarfTail", &"foot_l": "FootL", &"foot_r": "FootR",
	})
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

	_guide_setup(^"Torso/Head")
	_look_layer(&"ear_l", Vector2(-0.5, -0.2))
	_look_layer(&"ear_r", Vector2(-0.5, -0.2))
	_clip_set(OWN_CLIPS)
	fidgets = [&"look_around", &"ear_twitch", &"sniff", &"ear_twitch", &"ponder", &"stretch", &"wiggle"]
