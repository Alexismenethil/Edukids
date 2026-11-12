class_name CaimanCharacter
extends Puppet
## Coco, el caimán glotón. Flota y parpadea, mueve la cola en ondas, sigue la fruta con los ojos
## brillantes, abre la boca, atrapa al vuelo, mastica feliz, se enoja y muerde, y se duerme
## satisfecho entre zetas. Mira a la izquierda. Solo anima: las reglas viven en el dominio.
##
## El interior de la boca se dibuja por código entre las dos mandíbulas, así nunca asoma por fuera.

const RIG := preload("res://scenes/characters/caiman/caiman_rig.tscn")
## Bisagra de la mandíbula y labios, en el espacio de la cabeza (píxeles del rig).
const HINGE := Vector2(-12.0, 16.0)
## El borde de arriba queda escondido bajo la cabeza y el de abajo bajo la mandíbula: solo se ve
## la parte que deja la boca abierta.
const UPPER_HINGE := Vector2(-8.0, 10.0)
const UPPER_MID := Vector2(-120.0, 8.0)
const UPPER_TIP := Vector2(-226.0, 8.0)
const JAW_TIP := Vector2(-216.0, 4.0)
const JAW_MID := Vector2(-110.0, 6.0)
const JAW_HINGE := Vector2(-4.0, 6.0)

const EXPRESSIONS := {
	&"neutral": {"eyes": &"open"},
	&"calm": {"eyes": &"open"},
	&"happy": {"eyes": &"happy", "show": [&"cheek"], "blink": false},
	&"joy": {"eyes": &"happy", "show": [&"cheek"], "blink": false},
	&"laugh": {"eyes": &"happy", "show": [&"cheek"], "blink": false},
	&"angry": {"eyes": &"angry", "blink": false},
	&"determined": {"eyes": &"angry", "blink": false},
	&"sleepy": {"eyes": &"closed", "show": [&"cheek"], "blink": false},
	&"wow": {"eyes": &"wow", "show": [&"cheek"], "blink": false},
	&"worry": {"eyes": &"wow", "blink": false},
	&"ouch": {"eyes": &"closed", "blink": false},
	&"dizzy": {"eyes": &"closed", "blink": false},
}

const CLIPS := {
	# Se relame: abre y cierra la boca despacito.
	&"lick": {"group": &"head", "tracks": {
		"param:mouth": [[0.2, 0.3, "out"], [0.4, 0.05], [0.6, 0.25], [0.85, 0.0]],
		"head:rot": [[0.2, 0.06], [0.6, 0.04], [0.9, 0.0]],
		"face": [[0.0, "happy"], [0.9, ""]],
	}},
	# Bosteza con toda la boca.
	&"yawn": {"group": &"head", "tracks": {
		"param:mouth": [[0.6, 0.85, "inout"], [1.1, 0.85], [1.6, 0.0]],
		"head:rot": [[0.6, 0.14], [1.1, 0.14], [1.6, 0.0]],
		"face": [[0.3, "sleepy"], [1.7, ""]],
	}},
	# Da un coletazo juguetón.
	&"tail_slap": {"group": &"tail", "tracks": {
		"tail:rot": [[0.16, -0.5, "out"], [0.3, 0.28, "in"], [0.7, 0.0, "elastic"]],
		"squash": [[0.3, [1.03, 0.96]], [0.6, [1.0, 1.0]]],
		"cue": [[0.3, "splash"]],
	}},
	# Se hunde un poco y vuelve a salir (cosquillas).
	&"bob": {"group": &"body", "tracks": {
		"shift": [[0.2, [0.0, 16.0], "out"], [0.5, [0.0, -8.0], "out"], [0.9, [0.0, 0.0], "elastic"]],
		"param:mouth": [[0.2, 0.2], [0.6, 0.0]],
		"face": [[0.0, "wow"], [0.5, "happy"], [1.1, ""]],
		"cue": [[0.2, "splash"]],
	}, "length": 1.2},
}

## calm, happy, angry, sleepy o wow.
var mood: StringName = &"calm"
## Qué tan abierta está la boca: 0 cerrada, 1 abierta del todo.
var mouth := 0.0
## De 0 a 1: la panza crece un poco con cada fruta.
var fullness := 0.0
## De 0 a 1: fuera del agua, con las patas abiertas y la cola como látigo.
var airborne := 0.0
## Nada hacia adelante: la cola ondula más rápido y las patas reman.
var swim := 0.0

var _head: Node2D
var _jaw: Node2D
var _cavity: _Cavity
var _tail: BendStrip
var _body_bone: PuppetBone
var _head_bone: PuppetBone
var _jaw_bone: PuppetBone
var _tail_bone: PuppetBone
var _leg_front: PuppetBone
var _leg_back: PuppetBone
var _chewing := 0.0
var _lunge := 0.0
var _tilt := 0.0
var _gulp := 0.0
var _gesture: Tween
var _held: Node2D
var _snooze := 0.0


func _setup() -> void:
	_use_rig(RIG)
	_head = _rig.get_node("Head")
	_jaw = _rig.get_node("Head/Jaw")
	_head.scale = Vector2(1.12, 1.12)
	_bone_map({
		&"head": "Head", &"jaw": "Head/Jaw", &"tail": "Tail", &"body": "BodyArt",
		&"leg_front": "LegFront", &"leg_back": "LegBack",
	})
	_body_bone = get_bone(&"body")
	_head_bone = get_bone(&"head")
	_jaw_bone = get_bone(&"jaw")
	_tail_bone = get_bone(&"tail")
	_leg_front = get_bone(&"leg_front")
	_leg_back = get_bone(&"leg_back")
	_tail = BendStrip.from_sprite(_tail_bone.node as Sprite2D, Vector2.ZERO, Vector2(204.0, -4.0), 9)
	_tail_bone.node = _tail
	_cavity = _Cavity.new()
	_cavity.name = "Cavity"
	_head.add_child(_cavity)
	_head.move_child(_cavity, _jaw.get_index())

	shadow_scale = 0.0
	grounded = false
	hit_rect = Rect2(-250.0, -160.0, 480.0, 190.0)
	body_center = Vector2(0.0, -60.0)
	emote_anchor = Vector2(-150.0, -190.0)
	emote_size = 1.2
	look_range = Vector2(7.0, 6.0)
	look_nod = -0.05
	look_reach = 460.0
	curious = true

	_face_setup(^"Head", EXPRESSIONS, {"blinkable": [&"open"]})
	face.add_extra(&"cheek", _rig.get_node("Head/Cheek"))
	_look_layer(&"eyes", Vector2(1.0, 1.0))
	_clip_set(CLIPS)
	fidgets = [&"lick", &"tail_slap", &"yawn", &"look_around"]
	fidget_wait = Vector2(6.0, 12.0)
	tap_reactions = [&"bob", &"tail_slap", &"lick"]
	set_mood(mood)


func _animate(delta: float) -> void:
	var sleepy := mood == &"sleepy"
	var angry := mood == &"angry"
	var bob_speed := 0.9 if sleepy else 1.7
	var air := airborne
	_b_shift += Vector2(-_lunge, sin(_time * bob_speed) * (2.0 if sleepy else 3.5) * (1.0 - air))
	_b_lean += 0.012 * sin(_time * bob_speed * 0.7) * (1.0 - air)
	# Patas: reman al nadar, se abren en el aire.
	var paddle := 0.0 if sleepy else (0.18 + swim * 0.3)
	var stroke := _time * (3.1 + swim * 5.0)
	_leg_front.rotation += lerpf(paddle * sin(stroke), 0.85 + 0.1 * sin(_time * 14.0), air)
	_leg_back.rotation += lerpf(paddle * sin(stroke + 1.6), -0.75 + 0.1 * sin(_time * 14.0 + 1.0), air)
	_gulp = maxf(0.0, _gulp - delta * 1.6)
	var swallow := sin(clampf(1.0 - _gulp, 0.0, 1.0) * PI) if _gulp > 0.0 else 0.0
	_body_bone.scale *= Vector2(1.0 + fullness * 0.04 + swallow * 0.05,
		1.0 + fullness * 0.1 + 0.012 * sin(_time * 2.0) + swallow * 0.08)
	var head_bob := 0.0
	if _chewing > 0.0:
		_chewing = maxf(0.0, _chewing - delta)
		var chew := absf(sin(_time * 11.0))
		mouth = 0.16 * chew
		head_bob = -chew * 3.0
		if _chewing <= 0.0:
			mouth = 0.0
			_gulp = 1.0
			if mood == &"happy":
				set_mood(&"calm")
	_head_bone.position.y += head_bob + sin(_time * bob_speed + 0.6) * 1.5
	_head_bone.rotation += _tilt + swallow * 0.12 - air * 0.08
	# Cola: ondas que viajan hasta la punta; más rápidas al nadar o enojado, látigo en el aire.
	var beat := 2.2 + swim * 4.0 + (1.5 if angry else 0.0)
	if sleepy:
		beat = 1.0
	_tail_bone.rotation += lerpf(0.04 * sin(_time * beat * 0.5), -0.28 + 0.12 * sin(_time * 9.0), air)
	# Dormido, suelta zetas de vez en cuando.
	if sleepy and delta > 0.0:
		_snooze -= delta
		if _snooze <= 0.0:
			_snooze = 2.6
			emote(&"zzz", 2.4)


func _after_pose(_delta: float) -> void:
	var opening := clampf(mouth + param(&"mouth"), 0.0, 1.2)
	_jaw.rotation = _jaw_bone.rest_rotation + _jaw_bone.rotation - 0.5 * opening
	if _held and is_instance_valid(_held):
		_held.position = _mouth_center()
	var sleepy := mood == &"sleepy"
	var air := airborne
	var beat := 1.0 if sleepy else 2.2 + swim * 4.0 + (1.5 if mood == &"angry" else 0.0)
	var sway := (0.18 if sleepy else 0.42 + swim * 0.35) * (1.0 - air)
	_tail.wave(lerpf(0.06, 0.55, air), sway + air * 0.5, _time * (beat + air * 6.0), 1.2)
	_cavity.queue_redraw()


## Cambia la expresión: calm, happy, angry, sleepy o wow.
func set_mood(new_mood: StringName) -> void:
	mood = new_mood
	set_expression(new_mood)
	if new_mood == &"sleepy":
		_snooze = 0.6


## Abre la boca de par en par, esperando la fruta, con los ojos brillantes.
func open_wide(seconds: float = 0.25) -> Tween:
	_kill_gesture()
	if mood == &"calm":
		express(&"wow", seconds + 0.6)
	_gesture = create_tween()
	_gesture.tween_property(self, "mouth", 1.0, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return _gesture


## Punto de la boca abierta, en coordenadas globales (donde entra la fruta).
func mouth_point() -> Vector2:
	if _head == null:
		return global_position
	return _head.to_global(_mouth_center())


## Guarda algo dentro de la boca (la fruta que atrapa): se dibuja entre las mandíbulas y se va con
## la cabeza hasta que `chomp` la cierra.
func hold(item: Node2D) -> void:
	if _head == null:
		return
	if _held and is_instance_valid(_held):
		_held.queue_free()
	_held = item
	if item.get_parent():
		item.reparent(_head, true)
	else:
		_head.add_child(item)
	_head.move_child(item, _cavity.get_index() + 1)
	item.z_index = 0
	item.position = _mouth_center()


## ¡Ñam! Cierra la boca de golpe y mastica feliz.
func chomp(chew_seconds: float = 1.3) -> Tween:
	_kill_gesture()
	_gesture = create_tween()
	_gesture.tween_property(self, "mouth", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_gesture.parallel().tween_property(self, "squash", Vector2(1.06, 0.92), 0.08)
	_gesture.tween_callback(func() -> void:
		if _held and is_instance_valid(_held):
			_held.queue_free()
		_held = null
		set_mood(&"happy")
		_chewing = chew_seconds)
	_gesture.tween_property(self, "squash", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return _gesture


## Se enoja y muerde hacia adelante dos veces (sin alcanzar a nadie).
func snap(distance: float = 70.0) -> Tween:
	_kill_gesture()
	set_mood(&"angry")
	emote(&"anger", 1.1)
	_chewing = 0.0
	_gesture = create_tween()
	_gesture.tween_property(self, "_lunge", -10.0, 0.12)
	_gesture.parallel().tween_property(self, "mouth", 1.1, 0.12)
	_gesture.parallel().tween_property(self, "_tilt", 0.1, 0.12)
	_gesture.tween_property(self, "_lunge", distance, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_gesture.tween_property(self, "mouth", 0.0, 0.06)
	_gesture.parallel().tween_property(self, "_tilt", -0.06, 0.06)
	_gesture.tween_property(self, "mouth", 0.9, 0.08)
	_gesture.parallel().tween_property(self, "_tilt", 0.08, 0.08)
	_gesture.tween_property(self, "mouth", 0.0, 0.06)
	_gesture.parallel().tween_property(self, "_tilt", 0.0, 0.06)
	_gesture.tween_interval(0.2)
	_gesture.tween_property(self, "_lunge", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	return _gesture


## Bosteza y se duerme flotando.
func fall_asleep() -> Tween:
	_kill_gesture()
	_chewing = 0.0
	set_mood(&"happy")
	_gesture = create_tween()
	_gesture.tween_property(self, "mouth", 0.75, 0.6).set_trans(Tween.TRANS_SINE)
	_gesture.parallel().tween_property(self, "_tilt", 0.16, 0.6).set_trans(Tween.TRANS_SINE)
	_gesture.tween_interval(0.35)
	_gesture.tween_property(self, "mouth", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	_gesture.parallel().tween_property(self, "_tilt", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	_gesture.tween_callback(set_mood.bind(&"sleepy"))
	return _gesture


func react_to_petting() -> void:
	play(&"lick")
	emote(&"heart")


func _kill_gesture() -> void:
	if _gesture and _gesture.is_running():
		_gesture.kill()


## Centro de la boca abierta, en el espacio de la cabeza.
func _mouth_center() -> Vector2:
	var lower := HINGE + Vector2(-124.0, -2.0).rotated(_jaw.rotation if _jaw else 0.0)
	return (lower + Vector2(-124.0, 16.0)) * 0.5 + Vector2(-8.0, 0.0)


## El interior de la boca: se arma cada cuadro entre el labio de arriba y la mandíbula que gira,
## con la garganta más oscura y la lengua apoyada sobre la mandíbula.
class _Cavity:
	extends Node2D

	const FLESH := Color("#8E2236")
	const THROAT := Color("#5E1424")
	const TONGUE := Color("#E8697A")
	const TONGUE_LINE := Color("#C44660")
	const LINE := Color("#24502C")

	func _draw() -> void:
		var coco := get_parent().get_parent().get_parent().get_parent() as CaimanCharacter
		if coco == null or coco._jaw == null:
			return
		var angle := coco._jaw.rotation
		if angle > -0.012:
			return
		var jaw := func(point: Vector2) -> Vector2: return HINGE + point.rotated(angle)
		var lower_tip: Vector2 = jaw.call(JAW_TIP)
		var opening := (UPPER_TIP + lower_tip) * 0.5
		var inward := (UPPER_HINGE - opening).normalized() * UPPER_TIP.distance_to(lower_tip) * 0.16
		var cavity := PackedVector2Array([UPPER_HINGE, UPPER_MID, UPPER_TIP, opening + inward,
			lower_tip, jaw.call(JAW_MID), jaw.call(JAW_HINGE)])
		draw_colored_polygon(cavity, FLESH)
		var throat := PackedVector2Array([UPPER_HINGE, Vector2(-64.0, 9.0), jaw.call(Vector2(-64.0, 6.0)), jaw.call(JAW_HINGE)])
		draw_colored_polygon(throat, THROAT)
		var tongue := PackedVector2Array()
		for point: Vector2 in [Vector2(-18, -2), Vector2(-46, -13), Vector2(-104, -17), Vector2(-150, -13),
				Vector2(-170, -5), Vector2(-150, 0)]:
			tongue.append(jaw.call(point))
		draw_colored_polygon(tongue, TONGUE)
		draw_polyline(PackedVector2Array([jaw.call(Vector2(-40, -6)), jaw.call(Vector2(-100, -9)), jaw.call(Vector2(-140, -7))]),
			TONGUE_LINE, 3.0, true)
		var outline := cavity.duplicate()
		outline.append(cavity[0])
		draw_polyline(outline, LINE, 5.0, true)
