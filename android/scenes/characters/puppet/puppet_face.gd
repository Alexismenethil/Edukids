class_name PuppetFace
extends RefCounted
## La cara de un títere: expresiones con nombre, parpadeo, habla y cejas. Las piezas se descubren
## solas por su nombre en el rig: los hijos de `Eyes` que empiezan con «Eyes» son variantes de
## ojos (`EyesOpen` → open), los de `Mouth` que empiezan con «Mouth» son bocas, y el resto de
## piezas sueltas (rubor, pestañas) quedan como extras que cada expresión puede mostrar u ocultar.
##
## Una expresión es un diccionario:
##   {"eyes": &"happy", "mouth": &"open", "brows": 6.0, "tilt": -0.2, "eyes_scale": 1.1,
##    "mouth_scale": Vector2(1, -1), "show": [&"cheek"], "hide": [&"blush"], "blink": false}
## `brows` sube las cejas (píxeles del rig), `tilt` las inclina (positivo: preocupado; negativo:
## decidido o enojado) y una escala negativa en la boca la voltea (sonrisa → puchero).

const CHANGE_RATE := 16.0

var eyes: Dictionary = {}
var mouths: Dictionary = {}
var extras: Dictionary = {}
var expressions: Dictionary = {&"neutral": {}}
## Estado de ánimo de base.
var mood: StringName = &"neutral"
## Variante de ojos del parpadeo y las que pueden parpadear.
var blink_eyes: StringName = &"closed"
var blinkable: Array[StringName] = [&"open"]
## Bocas que se alternan al hablar.
var talk_shapes: Array[StringName] = []
var talking := false
## Se llama cuando cambian los ojos o la boca que se ven.
var changed := Callable()
## Variantes que se ven ahora.
var current_eyes: StringName = &""
var current_mouth: StringName = &""

var _extra_defaults: Dictionary = {}
var _eyes_bone: PuppetBone
var _mouth_bone: PuppetBone
var _brow_l: PuppetBone
var _brow_r: PuppetBone
var _brows: PuppetBone
var _timed: StringName = &""
var _timed_left := 0.0
var _blink_wait := 2.0
var _blink_left := 0.0
var _blink_again := false
var _talk_wait := 0.0
var _talk_shape: StringName = &""
var _brow_lift := 0.0
var _brow_tilt := 0.0
var _eyes_scale := Vector2.ONE
var _mouth_scale := Vector2.ONE
var _eye_pop := 0.0
var _mouth_pop := 0.0
var _last_expression: StringName = &""


## Registra las piezas de la cara que cuelgan de `head`.
func discover(head: Node) -> void:
	for child in head.get_children():
		var group := String(child.name)
		if group == "Eyes" or group == "Mouth":
			for piece in child.get_children():
				var piece_name := String(piece.name)
				if piece_name.begins_with(group) and piece_name.length() > group.length():
					var variant := StringName(piece_name.substr(group.length()).to_snake_case())
					if group == "Eyes":
						eyes[variant] = piece
					else:
						mouths[variant] = piece
				else:
					add_extra(StringName(piece_name.to_snake_case()), piece as CanvasItem)
	_blink_wait = randf_range(1.0, 3.5)


## Una pieza que las expresiones muestran u ocultan (rubor, pestañas, lágrima).
func add_extra(extra: StringName, item: CanvasItem) -> void:
	if item == null:
		return
	extras[extra] = item
	_extra_defaults[extra] = item.visible


## Cambia la visibilidad de base de un extra (las pestañas de un avatar, por ejemplo).
func set_extra_default(extra: StringName, visible: bool) -> void:
	if extras.has(extra):
		_extra_defaults[extra] = visible
		_last_expression = &""


func bind(eyes_bone: PuppetBone, mouth_bone: PuppetBone, brow_l: PuppetBone, brow_r: PuppetBone, brows: PuppetBone) -> void:
	_eyes_bone = eyes_bone
	_mouth_bone = mouth_bone
	_brow_l = brow_l
	_brow_r = brow_r
	_brows = brows


## Pone una expresión por unos segundos; después vuelve al estado de ánimo.
func express(expression: StringName, seconds: float) -> void:
	_timed = expression
	_timed_left = seconds


## Parpadea ahora (al cambiar la mirada, por ejemplo).
func blink() -> void:
	if _blink_left <= 0.0:
		_blink_left = 0.1


## Nombre de la expresión que manda ahora: la del clip, la temporal o el estado de ánimo.
func active(clip_face: StringName = &"") -> StringName:
	if clip_face != &"" and expressions.has(clip_face):
		return clip_face
	if _timed != &"" and expressions.has(_timed):
		return _timed
	return mood if expressions.has(mood) else &"neutral"


func update(delta: float, clip_face: StringName = &"") -> void:
	if _timed_left > 0.0:
		_timed_left -= delta
		if _timed_left <= 0.0:
			_timed = &""
	var expression_name := active(clip_face)
	var expression: Dictionary = expressions.get(expression_name, {})
	_update_blink(delta, expression)
	_update_talk(delta)
	var eyes_variant: StringName = expression.get("eyes", &"open")
	if _blink_left > 0.0 and eyes_variant in blinkable and eyes.has(blink_eyes):
		eyes_variant = blink_eyes
	var mouth_variant: StringName = expression.get("mouth", &"smile")
	if talking and _talk_shape != &"":
		mouth_variant = _talk_shape
	var dirty := expression_name != _last_expression
	if eyes_variant != current_eyes:
		if expression_name != _last_expression:
			_eye_pop = 1.0
		_show_only(eyes, eyes_variant)
		current_eyes = eyes_variant
		dirty = true
	if mouth_variant != current_mouth:
		if not talking:
			_mouth_pop = 1.0
		_show_only(mouths, mouth_variant)
		current_mouth = mouth_variant
		dirty = true
	if dirty:
		_last_expression = expression_name
		var show: Array = expression.get("show", [])
		var hide: Array = expression.get("hide", [])
		for extra: StringName in extras:
			var visible: bool = _extra_defaults[extra]
			if extra in show:
				visible = true
			elif extra in hide:
				visible = false
			(extras[extra] as CanvasItem).visible = visible
		if changed.is_valid():
			changed.call()
	var rate := minf(1.0, delta * CHANGE_RATE)
	_brow_lift = lerpf(_brow_lift, float(expression.get("brows", 0.0)), rate)
	_brow_tilt = lerpf(_brow_tilt, float(expression.get("tilt", 0.0)), rate)
	_eyes_scale = _eyes_scale.lerp(_as_scale(expression.get("eyes_scale", 1.0)), rate)
	_mouth_scale = _mouth_scale.lerp(_as_scale(expression.get("mouth_scale", 1.0)), minf(1.0, delta * 26.0))
	_eye_pop = maxf(0.0, _eye_pop - delta * 7.0)
	_mouth_pop = maxf(0.0, _mouth_pop - delta * 7.0)
	if _eyes_bone:
		var pop := sin(_eye_pop * PI) * 0.22
		_eyes_bone.scale *= _eyes_scale * Vector2(1.0 + pop * 0.5, 1.0 - pop)
	if _mouth_bone:
		var pop := sin(_mouth_pop * PI) * 0.25
		var chatter := 1.0 + (0.08 * sin(_talk_wait * 60.0) if talking else 0.0)
		_mouth_bone.scale *= _mouth_scale * Vector2(1.0 + pop, (1.0 + pop * 0.6) * chatter)
	if _brow_l:
		_brow_l.position.y -= _brow_lift
		_brow_l.rotation -= _brow_tilt
	if _brow_r:
		_brow_r.position.y -= _brow_lift
		_brow_r.rotation += _brow_tilt
	if _brows:
		_brows.position.y -= _brow_lift


func _update_blink(delta: float, expression: Dictionary) -> void:
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0 and _blink_again:
			_blink_again = false
			_blink_wait = 0.12
		return
	if not expression.get("blink", true):
		return
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = 0.1
		_blink_again = randf() < 0.18
		_blink_wait = randf_range(2.0, 5.0)


func _update_talk(delta: float) -> void:
	if not talking or talk_shapes.is_empty():
		_talk_shape = &""
		return
	_talk_wait -= delta
	if _talk_wait <= 0.0:
		_talk_wait = randf_range(0.07, 0.15)
		var next := talk_shapes[randi() % talk_shapes.size()]
		if next == _talk_shape:
			next = talk_shapes[(talk_shapes.find(next) + 1) % talk_shapes.size()]
		_talk_shape = next


func _show_only(pieces: Dictionary, variant: StringName) -> void:
	if not pieces.has(variant):
		return
	for key: StringName in pieces:
		(pieces[key] as CanvasItem).visible = key == variant


func _as_scale(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	return Vector2(float(value), float(value))
