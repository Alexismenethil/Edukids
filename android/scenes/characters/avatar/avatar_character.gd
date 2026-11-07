class_name AvatarCharacter
extends Node2D
## Avatar del estudiante armado por piezas (RF-31). Tiñe cada pieza con los colores elegidos
## y le da vida: respira, parpadea, saluda, celebra y salta. No conoce casos de uso ni datos.
##
## El origen está entre los pies; el personaje mide HEIGHT unidades hacia arriba.

const RIG := preload("res://scenes/characters/avatar/avatar_rig.tscn")
const HEIGHT := 386.0
const SHADOW_COLOR := Color(0.2, 0.12, 0.05, 0.2)
const HAIR_STYLES := 6

const SKIN_PARTS: Array[String] = ["LegL", "LegR", "Torso/Neck", "Torso/ArmL/HandL", "Torso/ArmR/HandR", "Torso/Head/HeadArt"]
const TOP_PARTS: Array[String] = ["Torso/TorsoArt", "Torso/ArmL/SleeveL", "Torso/ArmR/SleeveR"]
const BOTTOM_PARTS: Array[String] = ["Pants", "Skirt"]
## Piezas de color propio: se ocultan en la silueta.
const DETAIL_PARTS: Array[String] = [
	"Socks", "Torso/Band", "Torso/Head/Blush", "Torso/Head/Eyes", "Torso/Head/Brows",
	"Torso/Head/Mouth", "HairBack/HairTie4", "Torso/Head/HairFront/HairTie3",
]

## Respira y parpadea solo. Desactívalo para retratos quietos.
@export var lively := true
## Escala de la sombra en el suelo (0 la oculta).
@export var shadow_scale := 1.0

## Estiramiento y aplastamiento de los saltos.
var squash := Vector2.ONE:
	set(value):
		squash = value
		if _rig:
			_rig.scale = _rig_scale * value

var _rig: Node2D
var _rig_scale := Vector2.ONE
var _torso: Node2D
var _head: Node2D
var _arm_l: Node2D
var _arm_r: Node2D
var _hair_back: Node2D
var _hair_front: Node2D
var _eyes_open: Sprite2D
var _eyes_closed: Sprite2D
var _eyes_happy: Sprite2D
var _lashes: Sprite2D
var _mouth_smile: Sprite2D
var _mouth_open: Sprite2D
var _look: AvatarLookViewModel
var _time := 0.0
var _blink_in := 2.0
var _blinking := false
var _happy := false
var _gesture: Tween
var _hop_tween: Tween


func _ready() -> void:
	_rig = RIG.instantiate()
	add_child(_rig)
	_rig_scale = _rig.scale
	_torso = _rig.get_node("Torso")
	_head = _rig.get_node("Torso/Head")
	_arm_l = _rig.get_node("Torso/ArmL")
	_arm_r = _rig.get_node("Torso/ArmR")
	_hair_back = _rig.get_node("HairBack")
	_hair_front = _rig.get_node("Torso/Head/HairFront")
	_eyes_open = _rig.get_node("Torso/Head/Eyes/EyesOpen")
	_eyes_closed = _rig.get_node("Torso/Head/Eyes/EyesClosed")
	_eyes_happy = _rig.get_node("Torso/Head/Eyes/EyesHappy")
	_lashes = _rig.get_node("Torso/Head/Eyes/Lashes")
	_mouth_smile = _rig.get_node("Torso/Head/Mouth/MouthSmile")
	_mouth_open = _rig.get_node("Torso/Head/Mouth/MouthOpen")
	# El cabello de atrás sigue a la cabeza aunque se dibuja detrás del cuerpo.
	var follow := RemoteTransform2D.new()
	follow.name = "HairBackFollow"
	_head.add_child(follow)
	follow.remote_path = follow.get_path_to(_hair_back)
	_time = randf() * TAU
	_blink_in = randf_range(1.0, 3.5)
	if _look:
		apply(_look)


func _draw() -> void:
	if shadow_scale > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.22) * shadow_scale)
		draw_circle(Vector2.ZERO, 64.0, SHADOW_COLOR)


func _process(delta: float) -> void:
	if not lively or _rig == null:
		return
	_time += delta
	var breath := sin(_time * 2.2)
	_torso.scale = Vector2(1.0 - breath * 0.006, 1.0 + breath * 0.012)
	_head.rotation = sin(_time * 1.1) * 0.035
	if _gesture == null or not _gesture.is_running():
		_arm_l.rotation = sin(_time * 2.2 + 0.6) * 0.04
		_arm_r.rotation = -sin(_time * 2.2 + 0.6) * 0.04
	_blink_in -= delta
	if _blink_in <= 0.0 and not _happy:
		_blink()


## Viste al personaje con su aspecto. Se puede llamar antes o después de entrar al árbol.
func apply(look: AvatarLookViewModel) -> void:
	_look = look
	if _rig == null:
		return
	for path in SKIN_PARTS:
		_tint(path, look.skin)
	for path in TOP_PARTS:
		_tint(path, look.top)
	for path in BOTTOM_PARTS:
		_tint(path, look.bottom)
	for style in HAIR_STYLES:
		var back := _rig.get_node("HairBack/HairBack%d" % style) as CanvasItem
		var front := _rig.get_node("Torso/Head/HairFront/HairFront%d" % style) as CanvasItem
		back.visible = style == look.hair_style
		front.visible = style == look.hair_style
		back.self_modulate = look.hair
		front.self_modulate = look.hair
	_tint("Torso/Head/Brows", look.hair)
	_rig.get_node("HairBack/HairTie4").visible = look.hair_style == 4 and not look.silhouette
	_rig.get_node("Torso/Head/HairFront/HairTie3").visible = look.hair_style == 3 and not look.silhouette
	_rig.get_node("Pants").visible = not look.is_girl
	_rig.get_node("Skirt").visible = look.is_girl
	_rig.get_node("Socks").visible = look.is_girl and not look.silhouette
	for path in DETAIL_PARTS:
		if path in ["Socks", "HairBack/HairTie4", "Torso/Head/HairFront/HairTie3"]:
			continue
		(_rig.get_node(path) as CanvasItem).visible = not look.silhouette
	var shoe_tint := look.skin if look.silhouette else Color.WHITE
	_tint("ShoeL", shoe_tint)
	_tint("ShoeR", shoe_tint)
	_update_face()


func look_model() -> AvatarLookViewModel:
	return _look


## Saluda con la mano derecha.
func wave() -> void:
	_start_gesture()
	_set_happy(true)
	_gesture.tween_property(_arm_r, "rotation", -2.55, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		_gesture.tween_property(_arm_r, "rotation", -2.2, 0.16).set_trans(Tween.TRANS_SINE)
		_gesture.tween_property(_arm_r, "rotation", -2.7, 0.16).set_trans(Tween.TRANS_SINE)
	_gesture.tween_property(_arm_r, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture.tween_callback(_set_happy.bind(false))


## Brazos arriba, ojos felices y un salto.
func celebrate() -> void:
	_start_gesture()
	_set_happy(true)
	_gesture.set_parallel(true)
	_gesture.tween_property(_arm_l, "rotation", 2.6, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture.tween_property(_arm_r, "rotation", -2.6, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture.chain().tween_interval(0.9)
	_gesture.chain().set_parallel(true)
	_gesture.tween_property(_arm_l, "rotation", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture.tween_property(_arm_r, "rotation", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture.chain().tween_callback(_set_happy.bind(false))
	hop(46.0)


## Niega con la cabeza, sin perder la sonrisa (PIN incorrecto).
func shake_head() -> void:
	_start_gesture()
	for i in 3:
		_gesture.tween_property(_head, "rotation", 0.14, 0.07)
		_gesture.tween_property(_head, "rotation", -0.14, 0.07)
	_gesture.tween_property(_head, "rotation", 0.0, 0.08)


## Salto con anticipación, estiramiento y aterrizaje.
func hop(height: float = 34.0) -> void:
	if _hop_tween:
		_hop_tween.kill()
	_hop_tween = create_tween()
	_hop_tween.tween_property(self, "squash", Vector2(1.1, 0.88), 0.08)
	_hop_tween.tween_property(self, "squash", Vector2(0.94, 1.08), 0.1)
	_hop_tween.parallel().tween_property(_rig, "position:y", -height, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_property(_rig, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_hop_tween.tween_property(self, "squash", Vector2(1.12, 0.88), 0.06)
	_hop_tween.tween_property(self, "squash", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Interrumpe el gesto anterior sin dejar la cara feliz ni los brazos arriba.
func _start_gesture() -> void:
	if _gesture and _gesture.is_running():
		_gesture.kill()
		_set_happy(false)
		var settle := create_tween().set_parallel(true)
		settle.tween_property(_arm_l, "rotation", 0.0, 0.2)
		settle.tween_property(_arm_r, "rotation", 0.0, 0.2)
		settle.tween_property(_head, "rotation", 0.0, 0.2)
	_gesture = create_tween()


func _tint(path: String, color: Color) -> void:
	(_rig.get_node(path) as CanvasItem).self_modulate = color


func _blink() -> void:
	_blinking = true
	_update_face()
	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(func() -> void:
		_blinking = false
		_update_face())
	_blink_in = randf_range(2.2, 5.0)


func _set_happy(value: bool) -> void:
	_happy = value
	_update_face()


func _update_face() -> void:
	if _look == null:
		return
	_eyes_open.visible = not _blinking and not _happy
	_eyes_closed.visible = _blinking and not _happy
	_eyes_happy.visible = _happy
	_lashes.visible = _look.is_girl and _eyes_open.visible
	_mouth_smile.visible = not _happy
	_mouth_open.visible = _happy
