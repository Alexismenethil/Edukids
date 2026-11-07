class_name QuwiCharacter
extends Node2D
## Quwi, el cuy guía de la Sierra, animado por piezas sobre el rig generado (quwi_rig.tscn).
## Respira, parpadea, mueve las orejas y la chalina, habla, salta y cambia de expresión.
## Solo anima: las reglas del juego viven en el dominio.

const SHADOW_COLOR := Color(0.2, 0.12, 0.05, 0.24)
const HIT_AREA := Rect2(-100.0, -295.0, 200.0, 305.0)
const HOP_SOUND := preload("res://assets/audio/sfx/sfx_quwi_hop.ogg")
const SQUEAK_SOUND := preload("res://assets/audio/sfx/sfx_quwi_squeak.ogg")

@onready var _hop: Node2D = $Hop
@onready var _torso: Node2D = $Hop/Rig/Torso
@onready var _head: Node2D = $Hop/Rig/Torso/Head
@onready var _ear_l: Node2D = $Hop/Rig/Torso/Head/EarL
@onready var _ear_r: Node2D = $Hop/Rig/Torso/Head/EarR
@onready var _arm_l: Node2D = $Hop/Rig/Torso/ArmL
@onready var _arm_r: Node2D = $Hop/Rig/Torso/ArmR
@onready var _scarf_tail: Node2D = $Hop/Rig/Torso/ScarfTail
@onready var _brows: Node2D = $Hop/Rig/Torso/Head/Brows
@onready var _eyes: Node2D = $Hop/Rig/Torso/Head/Eyes
@onready var _eyes_open: Node2D = $Hop/Rig/Torso/Head/Eyes/EyesOpen
@onready var _eyes_closed: Node2D = $Hop/Rig/Torso/Head/Eyes/EyesClosed
@onready var _eyes_happy: Node2D = $Hop/Rig/Torso/Head/Eyes/EyesHappy
@onready var _mouth_smile: Node2D = $Hop/Rig/Torso/Head/Mouth/MouthSmile
@onready var _mouth_open: Node2D = $Hop/Rig/Torso/Head/Mouth/MouthOpen
@onready var _mouth_o: Node2D = $Hop/Rig/Torso/Head/Mouth/MouthO
@onready var _voice: SfxPlayer = $Voice

## Valores que animan los gestos; _process los combina con la respiración.
var squash := Vector2.ONE
var head_tilt := 0.0
var brows_lift := 0.0
var eyes_offset := Vector2.ZERO

var _time := 0.0
var _mood: StringName = &"joy"
var _blinking := false
var _blink_wait := 1.6
var _talking := false
var _mouth_is_open := false
var _talk_wait := 0.0
var _ear_twitch := 0.0
var _ear_wait := 3.0
var _brows_base: Vector2
var _eyes_base: Vector2
var _gesture: Tween
var _reaction := 0


func _ready() -> void:
	_brows_base = _brows.position
	_eyes_base = _eyes.position
	_apply_face()


func _process(delta: float) -> void:
	_time += delta
	var breath := sin(_time * 2.4)
	_torso.scale = Vector2(1.0 - 0.012 * breath, 1.0 + 0.02 * breath) * squash
	_head.rotation = 0.035 * sin(_time * 1.3) + head_tilt
	_scarf_tail.rotation = 0.09 * sin(_time * 1.8) + 0.03 * sin(_time * 4.1)
	_ear_l.rotation = 0.06 * sin(_time * 2.1 + 0.6) - _ear_twitch
	_ear_r.rotation = -0.06 * sin(_time * 2.1) + _ear_twitch * 0.6
	_brows.position = _brows_base + Vector2(0, -brows_lift)
	_eyes.position = _eyes_base + eyes_offset
	_update_blink(delta)
	_update_talk(delta)
	_update_ears(delta)
	queue_redraw()


func _draw() -> void:
	var lift := clampf(-_hop.position.y / 90.0, 0.0, 0.7)
	var radius := Vector2(78.0, 11.0) * (1.0 - lift)
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle) * radius.x, 4.0 + sin(angle) * radius.y))
	draw_colored_polygon(points, Color(SHADOW_COLOR, SHADOW_COLOR.a * (1.0 - lift)))


## Cambia la expresión: joy, cheer, think, surprise, pride o comfort.
func set_mood(mood: StringName) -> void:
	_mood = mood
	var tween := _new_gesture()
	match mood:
		&"surprise":
			tween.tween_property(self, "brows_lift", 16.0, 0.12)
			tween.tween_property(self, "head_tilt", 0.0, 0.2)
			tween.tween_property(self, "eyes_offset", Vector2.ZERO, 0.2)
			hop(26.0)
		&"think":
			tween.tween_property(self, "brows_lift", 8.0, 0.25)
			tween.tween_property(self, "head_tilt", 0.1, 0.35).set_trans(Tween.TRANS_SINE)
			tween.tween_property(self, "eyes_offset", Vector2(8.0, -8.0), 0.3)
		&"cheer", &"pride":
			tween.tween_property(self, "brows_lift", 6.0, 0.2)
			tween.tween_property(self, "head_tilt", -0.05, 0.3).set_trans(Tween.TRANS_SINE)
			tween.tween_property(self, "eyes_offset", Vector2.ZERO, 0.2)
			arms_up()
		&"comfort":
			tween.tween_property(self, "brows_lift", 2.0, 0.3)
			tween.tween_property(self, "head_tilt", 0.08, 0.4).set_trans(Tween.TRANS_SINE)
			tween.tween_property(self, "eyes_offset", Vector2.ZERO, 0.2)
		_:
			tween.tween_property(self, "brows_lift", 0.0, 0.2)
			tween.tween_property(self, "head_tilt", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
			tween.tween_property(self, "eyes_offset", Vector2.ZERO, 0.2)
	_apply_face()


func talk(active: bool) -> void:
	_talking = active
	_mouth_is_open = active
	_talk_wait = 0.0
	_apply_face()


## Salto con anticipación, estiramiento y aterrizaje.
func hop(height: float = 38.0) -> void:
	_voice.play(HOP_SOUND, randf_range(0.94, 1.08) * (1.0 + (38.0 - height) / 160.0), -5.0)
	var tween := create_tween()
	tween.tween_property(self, "squash", Vector2(1.12, 0.86), 0.08)
	tween.tween_property(self, "squash", Vector2(0.92, 1.1), 0.1)
	tween.parallel().tween_property(_hop, "position:y", -height, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hop, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "squash", Vector2(1.14, 0.84), 0.07)
	tween.tween_property(self, "squash", Vector2.ONE, 0.32).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## El «wiik, wiik» de un cuy contento.
func squeak() -> void:
	_voice.play(SQUEAK_SOUND, randf_range(0.95, 1.12))


## ¿El punto (en coordenadas globales) toca a Quwi?
func contains_point(global_point: Vector2) -> bool:
	return HIT_AREA.has_point(to_local(global_point))


## Reacción al tocarlo: alterna entre festejar, saludar y sorprenderse.
func react_to_tap() -> void:
	squeak()
	match _reaction % 3:
		0:
			set_mood(&"cheer")
			hop(46.0)
		1:
			set_mood(&"joy")
			wave()
		_:
			set_mood(&"surprise")
	_reaction += 1


## Saluda con la mano derecha, delante de la cara.
func wave() -> void:
	_arm_r.z_index = 1
	var tween := create_tween()
	tween.tween_property(_arm_r, "rotation", -1.9, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		tween.tween_property(_arm_r, "rotation", -1.45, 0.15).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_arm_r, "rotation", -2.1, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_arm_r, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: _arm_r.z_index = 0)


## Levanta los dos brazos de alegría.
func arms_up() -> void:
	_arm_r.z_index = 1
	_arm_l.z_index = 1
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_arm_r, "rotation", -1.55, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_arm_l, "rotation", 1.55, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(0.5)
	tween.chain().tween_property(_arm_r, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(_arm_l, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func() -> void:
		_arm_r.z_index = 0
		_arm_l.z_index = 0)


## Celebración: ojos felices, brazos arriba y dos saltitos.
func celebrate() -> void:
	set_mood(&"cheer")
	var tween := create_tween()
	tween.tween_callback(hop.bind(42.0))
	tween.tween_interval(0.62)
	tween.tween_callback(hop.bind(30.0))
	tween.tween_interval(0.7)
	tween.tween_callback(set_mood.bind(&"joy"))


## Entra saltando desde un costado hasta su lugar.
func enter_from(offset_x: float, hops: int = 3) -> void:
	var target := position.x
	position.x += offset_x
	var tween := create_tween()
	for i in hops:
		tween.tween_callback(hop.bind(30.0))
		tween.tween_property(self, "position:x", target + offset_x * (1.0 - float(i + 1) / hops), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.2)
	tween.tween_callback(wave)


func _new_gesture() -> Tween:
	if _gesture:
		_gesture.kill()
	_gesture = create_tween().set_parallel(true)
	return _gesture


func _update_blink(delta: float) -> void:
	_blink_wait -= delta
	if _blink_wait > 0.0:
		return
	_blinking = not _blinking
	_blink_wait = 0.11 if _blinking else randf_range(1.8, 4.5)
	_apply_face()


func _update_talk(delta: float) -> void:
	if not _talking:
		return
	_talk_wait -= delta
	if _talk_wait <= 0.0:
		_mouth_is_open = not _mouth_is_open
		_talk_wait = randf_range(0.07, 0.15)
		_apply_face()


func _update_ears(delta: float) -> void:
	_ear_wait -= delta
	if _ear_wait <= 0.0:
		_ear_wait = randf_range(2.5, 6.0)
		var tween := create_tween()
		tween.tween_property(self, "_ear_twitch", 0.22, 0.07)
		tween.tween_property(self, "_ear_twitch", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _apply_face() -> void:
	if not is_node_ready():
		return
	var happy_eyes := _mood in [&"cheer", &"pride", &"comfort"]
	_eyes_happy.visible = happy_eyes
	_eyes_closed.visible = not happy_eyes and _blinking
	_eyes_open.visible = not happy_eyes and not _blinking
	_eyes_open.scale = Vector2.ONE * (1.12 if _mood == &"surprise" else 1.0)
	_mouth_o.visible = _mood == &"surprise" and not _talking
	_mouth_open.visible = not _mouth_o.visible and (_mouth_is_open or (_mood == &"cheer" and not _talking))
	_mouth_smile.visible = not _mouth_o.visible and not _mouth_open.visible
