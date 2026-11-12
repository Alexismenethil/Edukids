class_name GrazingAnimal
extends Node2D
## Animal del paisaje (llama u oveja) que hace su vida solo: pasta con el cuello abajo, levanta la
## cabeza y rumia, mueve la cola, respira y de vez en cuando camina unos pasos. Las crías siguen a
## su mamá y dan saltitos. Se arma sobre los rigs recortados de esta carpeta (art-src/fauna).
##
##   var llama := GrazingAnimal.new()
##   llama.fleece = Color("#E3B07A")      # caramelo (solo la llama se tiñe)
##   plano.add_child(llama)

enum Kind { LLAMA, SHEEP }

const RIGS := {
	Kind.LLAMA: preload("res://scenes/world/fauna/llama_rig.tscn"),
	Kind.SHEEP: preload("res://scenes/world/fauna/sheep_rig.tscn"),
}
## Cuánto baja el cuello (llama) o la cabeza (oveja) para pastar, en radianes.
const GRAZE_ANGLE := {Kind.LLAMA: 1.72, Kind.SHEEP: 0.9}
const SHADOW := Color(0.18, 0.14, 0.05, 0.18)
## Piezas que se tiñen con el color del vellón (la manta y las borlas no).
const FLEECE_PARTS: Array[String] = ["Body", "Body/Tail", "Body/Neck", "Body/Neck/Head", "LegBF", "LegFF", "LegBN", "LegFN"]

@export var kind := Kind.LLAMA
## Color del vellón de la llama (blanca, caramelo, café...).
@export var fleece := Color.WHITE
## 1 mira a la derecha; -1 a la izquierda.
@export var facing := 1
## Hasta dónde camina a cada lado de su lugar.
@export var roam := 50.0
## Cría: juguetona, da saltitos y sigue a `follow`.
@export var young := false

## A quién sigue la cría (su mamá).
var follow: GrazingAnimal

var _rig: Node2D
var _body: Node2D
var _neck: Node2D
var _head: Node2D
var _tail: Node2D
var _legs: Array[Node2D] = []
var _body_y := 0.0
var _home_x := 0.0
var _target_x := 0.0
var _state := &"graze"
var _left := 0.0
var _time := 0.0
var _phase := 0.0
var _bend := 0.0
var _hop := 0.0
var _hop_tween: Tween


func _ready() -> void:
	_rig = RIGS[kind].instantiate()
	add_child(_rig)
	_body = _rig.get_node("Body")
	_body_y = _body.position.y
	_tail = _rig.get_node("Body/Tail")
	_tail.show_behind_parent = true
	if kind == Kind.LLAMA:
		_neck = _rig.get_node("Body/Neck")
		_head = _rig.get_node("Body/Neck/Head")
		for path in FLEECE_PARTS:
			(_rig.get_node(path) as CanvasItem).self_modulate = fleece
	else:
		_neck = _rig.get_node("Body/Head")
		_head = _neck
	for leg in ["LegFN", "LegBF", "LegFF", "LegBN"]:
		_legs.append(_rig.get_node(leg))
	_home_x = position.x
	_time = randf() * TAU
	_left = randf_range(0.5, 3.0)
	_state = [&"graze", &"look"][randi() % 2]
	_bend = GRAZE_ANGLE[kind] if _state == &"graze" else 0.0
	_face(facing)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, 46.0 if kind == Kind.LLAMA else 34.0, SHADOW, true, -1.0, true)


func _process(delta: float) -> void:
	if _rig == null:
		return
	_time += delta
	_left -= delta
	if young and follow and _state != &"walk":
		var spot := follow.position.x - follow.facing * 46.0
		if absf(position.x - spot) > 40.0:
			_walk_to(spot)
	if _state == &"walk":
		_step(delta)
	elif _left <= 0.0:
		_next()
	# Cuello: abajo para pastar, arriba para mirar y rumiar.
	var goal := 0.0
	match _state:
		&"graze":
			goal = GRAZE_ANGLE[kind]
		&"look":
			goal = -0.06
		&"walk":
			goal = 0.12 if kind == Kind.LLAMA else 0.1
	_bend = lerpf(_bend, goal, minf(1.0, delta * 2.6))
	var nibble := 0.07 * sin(_time * 10.0) if _state == &"graze" else 0.0
	var chew := 0.035 * sin(_time * 5.5) if _state == &"look" else 0.0
	if kind == Kind.LLAMA:
		_neck.rotation = _bend
		_head.rotation = -_bend * 0.55 + nibble + chew
	else:
		_neck.rotation = _bend + nibble + chew
	_tail.rotation = 0.22 * sin(_time * 3.2) + (0.3 * sin(_time * 14.0) if fmod(_time, 6.0) < 0.5 else 0.0)
	_body.scale = Vector2(1.0, 1.0 + 0.015 * sin(_time * 2.3))
	_rig.position.y = -_hop


## Camina hasta `x` (la usa también la cría para seguir a su mamá).
func _walk_to(x: float) -> void:
	_target_x = x
	_state = &"walk"
	_face(1 if x > position.x else -1)


func _next() -> void:
	var roll := randf()
	if roll < 0.28 and not young:
		var target := _home_x + randf_range(-roam, roam)
		if absf(target - position.x) > 16.0:
			_walk_to(target)
			return
	if young and roll < 0.35:
		_jump()
	_state = &"graze" if _state == &"look" else &"look"
	_left = randf_range(2.5, 5.5) if _state == &"graze" else randf_range(1.8, 3.6)


func _step(delta: float) -> void:
	var speed := 30.0 if kind == Kind.LLAMA else 22.0
	if young:
		speed *= 1.5
	position.x = move_toward(position.x, _target_x, speed * delta)
	_phase += delta * (8.0 if kind == Kind.LLAMA else 11.0)
	var swing := 0.32
	_legs[0].rotation = sin(_phase) * swing
	_legs[1].rotation = sin(_phase) * swing
	_legs[2].rotation = -sin(_phase) * swing
	_legs[3].rotation = -sin(_phase) * swing
	_body.position.y = _body_y - absf(sin(_phase)) * 2.0
	if is_equal_approx(position.x, _target_x):
		for leg in _legs:
			leg.rotation = 0.0
		_body.position.y = _body_y
		_state = &"graze"
		_left = randf_range(2.5, 5.0)


## Saltito de cría (las crías de llama brincan con las cuatro patas tiesas).
func _jump() -> void:
	if _hop_tween and _hop_tween.is_running():
		return
	_hop_tween = create_tween()
	_hop_tween.tween_property(self, "_hop", 16.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_property(self, "_hop", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_hop_tween.tween_property(self, "_hop", 10.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_property(self, "_hop", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _face(direction: int) -> void:
	facing = 1 if direction >= 0 else -1
	if _rig:
		_rig.scale.x = absf(_rig.scale.x) * facing
