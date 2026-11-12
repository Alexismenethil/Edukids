class_name CineStage
extends Control
## Escenario de cine: un mundo por capas (ParallaxWorld) a pantalla completa con su cámara y sus
## herramientas de dirección. Es la base de las mecánicas de juego (MechanicStage) y de los cortos
## (ShortPlayer), así todo el juego comparte los mismos encuadres y efectos.
##
##   frame(Shot.ACTION) / close_on(punto)   encuadres          shake(8)       sacudida
##   punch(0.06)                            golpe de zoom      hit_stop(0.08) pausa de impacto
##   flash(color)                           destello suave     cinema(true)   barras de cine
##   light(color)                           luz del mundo      watch(títere)  polvo de sus pasos

## Empieza o termina un momento de cine (barras negras).
signal cinema_changed(active: bool)

enum Shot { QUESTION, ACTION, CLOSE }

const VIGNETTE := preload("res://scenes/world/vignette.gdshader")

## El mundo con sus capas (null si la escena no usa mundo).
var world: ParallaxWorld
## Personajes y efectos del plano principal.
var actors: Node2D
## Alto de la franja libre arriba de la tarjeta de la pregunta (en la pantalla).
var question_band := 220.0
## Zoom de la cámara mientras se responde y en la acción.
var question_zoom := 0.7
var action_zoom := 1.16
## Dónde queda el suelo en la pantalla durante la acción (fracción del alto).
var action_ground := 0.86
## Dónde pisan los personajes (y del mundo) y el punto que sigue la cámara.
var ground_y := 650.0
var focus_x := 640.0
## Zoom del primer plano.
var close_zoom := 1.45
var _time := 0.0
var _shot := Shot.ACTION
var _shot_tween: Tween
var _shake_time := 0.0
var _shake_power := 0.0
var _close_focus := Vector2(640, 560)
var _kick := 0.0
var _bars: Array[ColorRect] = []
var _bars_tween: Tween
var _flash: ColorRect
var _tint_tween: Tween
var _frozen := false
var _custom_shot: Dictionary = {}


## Crea el mundo, lo arma con `_build_world` y pone encima la viñeta, el destello y las barras.
func open_world() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	world = ParallaxWorld.new()
	add_child(world)
	_build_world()
	var vignette := ColorRect.new()
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = VIGNETTE
	vignette.material = material
	add_child(vignette)
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	add_child(_flash)
	for i in 2:
		var bar := ColorRect.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.color = Color("#16110F")
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if i == 0 else Control.PRESET_BOTTOM_WIDE)
		add_child(bar)
		_bars.append(bar)
	resized.connect(func() -> void: _apply_shot(_shot_params(_shot) if _custom_shot.is_empty() else _custom_shot))


## Cada escena arma aquí sus capas y sus personajes (ver WorldSets).
func _build_world() -> void:
	pass


# --- Cámara -----------------------------------------------------------------------------------

## Cambia el encuadre: la franja de la pregunta, la acción a pantalla completa o un primer plano.
func frame(shot: Shot, seconds: float = 0.6) -> void:
	_shot = shot
	_custom_shot = {}
	if world == null:
		return
	if _shot_tween:
		_shot_tween.kill()
	var target := _shot_params(shot)
	if seconds <= 0.0 or size.x < 64.0:
		_apply_shot(target)
		return
	var start := {"focus": world.focus, "screen": world.screen_focus, "zoom": world.zoom}
	_shot_tween = create_tween()
	_shot_tween.tween_method(func(t: float) -> void:
		world.focus = (start["focus"] as Vector2).lerp(target["focus"], t)
		world.screen_focus = (start["screen"] as Vector2).lerp(target["screen"], t)
		world.zoom = lerpf(start["zoom"], target["zoom"], t),
		0.0, 1.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


## Encuadre libre: lleva el punto `focus` del mundo a la posición `anchor` de la pantalla (en
## fracciones del ancho y del alto) con el zoom pedido. Para los cortos y los momentos especiales.
func shoot(focus: Vector2, zoom: float, seconds: float = 0.8, anchor: Vector2 = Vector2(0.5, 0.62)) -> void:
	if world == null:
		return
	if _shot_tween:
		_shot_tween.kill()
	var view := size if size.x > 64.0 else Vector2(1280, 800)
	var target := {"focus": focus, "screen": view * anchor, "zoom": zoom}
	_custom_shot = target
	if seconds <= 0.0:
		_apply_shot(target)
		return
	var start := {"focus": world.focus, "screen": world.screen_focus, "zoom": world.zoom}
	_shot_tween = create_tween()
	_shot_tween.tween_method(func(t: float) -> void:
		world.focus = (start["focus"] as Vector2).lerp(target["focus"], t)
		world.screen_focus = (start["screen"] as Vector2).lerp(target["screen"], t)
		world.zoom = lerpf(start["zoom"], target["zoom"], t),
		0.0, 1.0, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


## Primer plano sobre un punto del mundo (por ejemplo, donde Atoq alcanza al avatar).
func close_on(point: Vector2, seconds: float = 0.45) -> void:
	_close_focus = point
	frame(Shot.CLOSE, seconds)


func _shot_params(shot: Shot) -> Dictionary:
	var view := size if size.x > 64.0 else Vector2(1280, 800)
	match shot:
		Shot.QUESTION:
			return {"focus": Vector2(focus_x, ground_y), "screen": Vector2(view.x * 0.5, question_band - 14.0),
				"zoom": question_zoom}
		Shot.CLOSE:
			return {"focus": _close_focus, "screen": Vector2(view.x * 0.5, view.y * 0.6), "zoom": close_zoom}
		_:
			return {"focus": Vector2(focus_x, ground_y), "screen": Vector2(view.x * 0.5, view.y * action_ground),
				"zoom": action_zoom}


func _apply_shot(params: Dictionary) -> void:
	if world == null:
		return
	world.view_size = size if size.x > 64.0 else Vector2(1280, 800)
	world.focus = params["focus"]
	world.screen_focus = params["screen"]
	world.zoom = params["zoom"]
	world.refresh()


## Sacude la cámara: golpes, caídas y mordiscos.
func shake(power: float = 9.0, seconds: float = 0.35) -> void:
	_shake_power = power
	_shake_time = seconds


## Golpe de zoom: la cámara se acerca un instante y vuelve (impactos, aciertos grandes).
func punch(amount: float = 0.06) -> void:
	_kick = maxf(_kick, amount)


## Pausa de impacto: el mundo se congela un instante para que el golpe se sienta.
func hit_stop(seconds: float = 0.08) -> void:
	if _frozen or not is_inside_tree():
		return
	_frozen = true
	Engine.time_scale = 0.05
	get_tree().create_timer(seconds, true, false, true).timeout.connect(_end_hit_stop)


func _end_hit_stop() -> void:
	_frozen = false
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	if _frozen:
		_end_hit_stop()


## Destello suave de un color sobre toda la escena (un solo pulso, nunca parpadeos).
func flash(color: Color = Color(1, 1, 1, 0.4), seconds: float = 0.3) -> void:
	if _flash == null:
		return
	_flash.color = color
	var tween := _flash.create_tween()
	tween.tween_property(_flash, "color:a", 0.0, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Barras de cine: entran para los momentos grandes (vida perdida, final) y salen después.
func cinema(active: bool, seconds: float = 0.35) -> void:
	if _bars.is_empty():
		return
	if _bars_tween:
		_bars_tween.kill()
	var height := (size.y if size.y > 64.0 else 800.0) * 0.085 if active else 0.0
	_bars_tween = create_tween().set_parallel(true)
	_bars_tween.tween_property(_bars[0], "offset_bottom", height, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_bars_tween.tween_property(_bars[1], "offset_top", -height, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cinema_changed.emit(active)


## Cambia la luz del mundo: dorada en la victoria, fría cuando el peligro alcanza al avatar.
func light(color: Color, seconds: float = 0.8) -> void:
	if world == null:
		return
	if _tint_tween:
		_tint_tween.kill()
	_tint_tween = create_tween()
	_tint_tween.tween_property(world, "modulate", color, seconds).set_trans(Tween.TRANS_SINE)


## Efectos que cualquier personaje pide por sus marcas: polvo al caer y al pisar fuerte.
func watch(puppet: Puppet, footsteps: bool = false) -> void:
	puppet.cue.connect(_on_puppet_cue.bind(puppet, footsteps))


func _on_puppet_cue(cue_name: StringName, puppet: Puppet, footsteps: bool) -> void:
	if not is_instance_valid(puppet) or not puppet.is_inside_tree():
		return
	var parent := puppet.get_parent()
	match cue_name:
		&"land":
			ToonFx.puff(parent, puppet.position + Vector2(0, -4), 6, 13.0)
		&"stomp":
			ToonFx.puff(parent, puppet.position + Vector2(40.0 * puppet.facing, -4), 4, 10.0)
			shake(3.0, 0.15)
		&"step":
			if footsteps:
				ToonFx.puff(parent, puppet.position + Vector2(-10.0 * puppet.facing, -2), 2, 8.0,
					Vector2(-160.0 * puppet.facing, 0.0))


func _process(delta: float) -> void:
	_time += delta
	if world == null:
		return
	world.view_size = size if size.x > 64.0 else Vector2(1280, 800)
	# La cámara respira: una deriva mínima para que el encuadre nunca quede muerto.
	var drift := Vector2(sin(_time * 0.43) * 3.0, sin(_time * 0.31 + 1.0) * 2.0)
	if _shake_time > 0.0:
		_shake_time -= delta
		var power := _shake_power * clampf(_shake_time / 0.35, 0.0, 1.0)
		world.shake_offset = drift + Vector2(randf_range(-power, power), randf_range(-power, power) * 0.7)
	else:
		world.shake_offset = drift
	_kick = maxf(0.0, _kick - delta * maxf(0.25, _kick * 7.0))
	world.kick = 1.0 + _kick
