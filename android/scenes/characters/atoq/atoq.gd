class_name AtoqCharacter
extends Puppet
## Atoq, el zorro andino travieso. Corre al galope con la cola al viento, acecha, se ríe a
## carcajadas, se lanza por un nudo, tropieza y queda mareado, gruñe, aúlla y olfatea. Mira a la
## derecha; con `facing = -1` mira a la izquierda. Solo anima: las reglas viven en el dominio.

const RIG := preload("res://scenes/characters/atoq/atoq_rig.tscn")

const EXPRESSIONS := {
	&"neutral": {"eyes": &"open", "mouth": &"grin"},
	&"happy": {"eyes": &"happy", "mouth": &"grin"},
	&"laugh": {"eyes": &"happy", "mouth": &"laugh", "blink": false},
	&"joy": {"eyes": &"happy", "mouth": &"laugh", "blink": false},
	&"wow": {"eyes": &"wide", "mouth": &"laugh", "blink": false},
	&"worry": {"eyes": &"wide", "mouth": &"grin", "blink": false},
	&"angry": {"eyes": &"angry", "mouth": &"grin", "blink": false},
	&"determined": {"eyes": &"angry", "mouth": &"grin", "blink": false},
	&"ouch": {"eyes": &"dizzy", "mouth": &"laugh", "blink": false},
	&"dizzy": {"eyes": &"dizzy", "mouth": &"laugh", "blink": false},
	&"sad": {"eyes": &"wide", "mouth": &"grin", "eyes_scale": Vector2(1.0, 0.85)},
	&"think": {"eyes": &"open", "mouth": &"grin"},
	&"proud": {"eyes": &"happy", "mouth": &"grin"},
}

const CLIPS := {
	# Tropieza de forma cómica: se va de bruces, ve estrellas y se levanta.
	&"stumble": {"group": &"body", "tracks": {
		"lean": [[0.14, 0.45, "out"], [0.32, 0.45], [0.72, 0.0, "elastic"]],
		"squash": [[0.14, [1.15, 0.85]], [0.32, [1.15, 0.85]], [0.72, [1.0, 1.0], "elastic"]],
		"tail:rot": [[0.14, 0.5, "out"], [0.7, 0.0]],
		"face": [[0.0, "wow"], [0.3, "dizzy"], [1.5, ""]],
		"emote": [[0.3, "dizzy"]],
	}, "length": 1.55},
	# Aúlla al cielo, orgulloso de su travesura.
	&"howl": {"group": &"head", "tracks": {
		"head:rot": [[0.3, -0.62, "back"], [1.3, -0.62], [1.6, 0.0]],
		"body:rot": [[0.3, -0.08], [1.3, -0.08], [1.6, 0.0]],
		"tail:rot": [[0.3, 0.3], [1.3, 0.3], [1.6, 0.0]],
		"face": [[0.25, "laugh"], [1.4, ""]],
		"emote": [[0.4, "note"]],
	}},
	# Olfatea el suelo buscando algo que llevarse.
	&"sniff": {"group": &"head", "tracks": {
		"head:rot": [[0.25, 0.4, "out"], [0.4, 0.34], [0.55, 0.42], [0.7, 0.34], [0.85, 0.42], [1.15, 0.0]],
		"body:rot": [[0.25, 0.05], [0.85, 0.05], [1.15, 0.0]],
		"ear_front:rot": [[0.3, 0.2], [0.85, 0.2], [1.15, 0.0]],
		"ear_back:rot": [[0.3, 0.2], [0.85, 0.2], [1.15, 0.0]],
	}},
	# Mueve la cola contento.
	&"wag": {"group": &"tail", "tracks": {
		"tail:rot": [[0.1, 0.3], [0.22, -0.2], [0.34, 0.3], [0.46, -0.2], [0.58, 0.3], [0.7, -0.2], [0.95, 0.0]],
		"face": [[0.0, "happy"], [0.9, ""]],
	}},
	# Gruñe y da un pisotón: se le escapó el nudo.
	&"grumble": {"group": &"body", "tracks": {
		"leg_fl:rot": [[0.12, -0.7, "out"], [0.2, 0.0, "in"], [0.36, -0.7, "out"], [0.44, 0.0, "in"]],
		"squash": [[0.2, [1.05, 0.95]], [0.3, [1.0, 1.0]], [0.44, [1.05, 0.95]], [0.6, [1.0, 1.0]]],
		"head:rot": [[0.15, 0.16], [0.6, 0.16], [0.9, 0.0]],
		"ear_front:rot": [[0.15, 0.5], [0.7, 0.5], [0.95, 0.0]],
		"ear_back:rot": [[0.15, 0.5], [0.7, 0.5], [0.95, 0.0]],
		"face": [[0.0, "angry"], [1.2, ""]],
		"emote": [[0.1, "anger"]],
		"cue": [[0.2, "stomp"], [0.44, "stomp"]],
	}, "length": 1.25},
	# Se agazapa para acechar.
	&"sneak": {"group": &"body", "tracks": {
		"squash": [[0.3, [1.06, 0.84], "out"], [1.3, [1.06, 0.84]], [1.6, [1.0, 1.0], "back"]],
		"head:rot": [[0.3, 0.2], [1.3, 0.2], [1.6, 0.0]],
		"ear_front:rot": [[0.3, 0.45], [1.3, 0.45], [1.6, 0.0]],
		"ear_back:rot": [[0.3, 0.45], [1.3, 0.45], [1.6, 0.0]],
		"tail:rot": [[0.3, -0.35], [1.3, -0.35], [1.6, 0.0]],
		"face": [[0.0, "determined"], [1.5, ""]],
	}},
}

## Velocidad del galope: 0 está quieto, 1 corre y 2 corre a toda velocidad.
var speed := 0.0:
	set(value):
		speed = value
		set_cycle(&"run", value)

var _laughing := 0.0
var _gesture: Tween
var _body: PuppetBone
var _head: PuppetBone


func _setup() -> void:
	_use_rig(RIG)
	_bone_map({
		&"body": "Body", &"head": "Body/Head", &"tail": "Body/Tail", &"bag": "Body/Bag",
		&"ear_front": "Body/Head/EarFront", &"ear_back": "Body/Head/EarBack",
		&"leg_fl": "Body/LegFL", &"leg_br": "Body/LegBR", &"leg_fr": "Body/LegFR", &"leg_bl": "Body/LegBL",
	})
	_body = get_bone(&"body")
	_head = get_bone(&"head")
	shadow_radius = 70.0
	shadow_flat = 0.18
	hit_rect = Rect2(-170.0, -235.0, 340.0, 245.0)
	body_center = Vector2(0.0, -90.0)
	emote_anchor = Vector2(118.0, -232.0)
	emote_size = 1.1
	look_range = Vector2(5.0, 4.0)
	look_nod = 0.2
	look_reach = 420.0

	_sway(&"body", "y", -1.5, 2.3)
	_sway(&"head", "rot", 0.05, 1.2)
	_sway(&"bag", "rot", 0.04, 1.7)
	_sway(&"ear_front", "rot", 0.05, 2.0)
	_sway(&"ear_back", "rot", 0.05, 2.0, 0.5)

	_strip(&"tail", Vector2.ZERO, Vector2(-192.0, -140.0), 8, {"wave": 0.22, "speed": 1.9, "curl": 1.0})
	_spring(&"tail", Vector2(-192.0, -140.0), 238.0, {"stiffness": 115.0, "damping": 6.5, "limit": 0.8, "drag": 0.035})
	_spring(&"ear_front", Vector2.UP, 110.0, {"stiffness": 230.0, "damping": 9.0, "limit": 0.5, "drag": 0.012})
	_spring(&"ear_back", Vector2.UP, 100.0, {"stiffness": 205.0, "damping": 9.0, "limit": 0.5, "drag": 0.012})
	_spring(&"bag", Vector2.DOWN, 120.0, {"stiffness": 150.0, "damping": 7.0, "limit": 0.4, "drag": 0.01})

	_face_setup(^"Body/Head", EXPRESSIONS, {"blink_eyes": &"happy"})
	_look_layer(&"eyes", Vector2(1.0, 1.0))

	_cycle(&"run", {"stride": 0.42, "rate": Vector2(0.4, 2.4), "gain": Vector2(0.6, 1.3), "travel": 210.0, "tracks": [
		["leg_fl:rot", 0.62],
		["leg_br:rot", -0.56],
		["leg_fr:rot", 0.62, 0.7],
		["leg_bl:rot", -0.56, 0.7],
		["lift", 9.0, 0.0, &"abs"],
		["body:rot", -0.06, 0.0, &"cos"],
		["head:rot", 0.07, 0.0, &"cos"],
		["tail:rot", 0.1, 0.0, &"sin", 0.5, -0.12],
		["bag:rot", 0.12, 1.2],
		["ear_front:rot", -0.14, PI * 0.5, &"abs"],
		["ear_back:rot", -0.16, PI * 0.5 + 0.3, &"abs"],
		["squash_x", 0.03, 0.0, &"cos"],
		["squash_y", -0.03, 0.0, &"cos"],
	]})

	_clip_set(CLIPS)
	fidgets = [&"sniff", &"wag", &"look_around", &"sneak", &"howl"]
	fidget_wait = Vector2(5.0, 10.0)
	tap_reactions = [&"grumble", &"laugh", &"howl", &"startle", &"wag"]


func _animate(delta: float) -> void:
	if _laughing > 0.0:
		_laughing -= delta
		_body.position.y -= absf(sin(_time * 18.0)) * 8.0
		_head.rotation += -0.12 + 0.06 * sin(_time * 18.0)


## Se ríe a carcajadas unos segundos.
func laugh(seconds: float = 1.4) -> void:
	_laughing = seconds
	express(&"laugh", seconds)


## Se sorprende (ojos muy abiertos).
func surprise(seconds: float = 0.9) -> void:
	_laughing = 0.0
	express(&"wow", seconds)


## Se lanza hacia adelante para llevarse un nudo: anticipación, estirón y vuelta.
func lunge(distance: float = 90.0) -> Tween:
	_kill_gesture()
	var start := position.x
	express(&"determined", 0.5)
	_gesture = create_tween()
	_gesture.tween_property(self, "lean", 0.18, 0.12)
	_gesture.parallel().tween_property(self, "squash", Vector2(1.12, 0.88), 0.12)
	_gesture.tween_property(self, "position:x", start + distance * facing, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture.parallel().tween_property(self, "lean", -0.1, 0.2)
	_gesture.parallel().tween_property(self, "lift", 26.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_gesture.parallel().tween_property(self, "squash", Vector2(0.92, 1.08), 0.15)
	_gesture.tween_property(self, "lift", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_gesture.parallel().tween_property(self, "squash", Vector2.ONE, 0.2)
	_gesture.parallel().tween_property(self, "lean", 0.0, 0.2)
	return _gesture


## Tropieza de forma cómica: se va de bruces y se levanta.
func stumble() -> void:
	_kill_gesture()
	_laughing = 0.0
	play(&"stumble")


func react_to_petting() -> void:
	play(&"wag")
	emote(&"heart")


func _kill_gesture() -> void:
	if _gesture and _gesture.is_running():
		_gesture.kill()
		lean = 0.0
		lift = 0.0
		squash = Vector2.ONE
