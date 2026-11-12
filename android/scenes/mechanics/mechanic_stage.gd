@abstract class_name MechanicStage
extends Control
## Escena de una mecánica de juego (diseño del juego, capítulo 04): un mundo a pantalla completa
## con cámara. Mientras se responde, la cámara encuadra la franja de arriba de la tarjeta; al
## responder, la tarjeta baja y la cámara abre a toda la pantalla para que la reacción se vea en
## grande (acierto, error o vida perdida). Todas las mecánicas comparten la regla del dominio (el
## medidor de peligro y las vidas); solo cambia cómo se ve.

## Terminó el final feliz (o el game over): ya se pueden mostrar los resultados.
signal payoff_finished
## El peligro alcanzó al avatar: es el momento de romper un corazón.
signal life_taken
## Empieza o termina un momento de cine (barras negras): la pantalla esconde su HUD.
signal cinema_changed(active: bool)

enum Shot { QUESTION, ACTION, CLOSE }

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const VIGNETTE := preload("res://scenes/world/vignette.gdshader")
const SKY_TOP := Color("#5DB6E6")
const SKY_BOTTOM := Color("#CFEFF8")

var area: AreaViewModel
var look: AvatarLookViewModel
var total := 0
var danger := 2
var danger_max := 4
var progress: Array[StringName] = []
## El mundo con sus capas (null en la mecánica clásica).
var world: ParallaxWorld
## Personajes y efectos: quietos respecto de la cámara.
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


func configure(intro: LevelIntroViewModel) -> void:
	area = intro.area
	look = intro.look
	total = intro.total
	danger = intro.danger
	danger_max = maxi(1, intro.danger_max)
	if intro.step:
		progress = intro.step.progress
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if _uses_world():
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
		resized.connect(func() -> void: _apply_shot(_shot_params(_shot)))


## Las mecánicas con mundo arman aquí sus capas y sus personajes.
func _build_world() -> void:
	pass


func _uses_world() -> bool:
	return true


## Entrada de la escena al abrir el nivel.
func start() -> void:
	pass


## Llega una pregunta nueva.
func question_shown(step: StepViewModel) -> void:
	progress = step.progress


## Reacciona a la respuesta (acierto, error, vida perdida). Devuelve cuántos segundos dura la
## reacción, para que la tarjeta vuelva después.
@abstract func react(feedback: FeedbackViewModel) -> float


## Final feliz. Emite payoff_finished al terminar.
@abstract func play_payoff() -> void


## Se acabaron las vidas. Emite payoff_finished al terminar.
@abstract func play_game_over() -> void


## Qué tan lejos está el peligro: 0 encima, 1 lo más lejos posible.
func safety() -> float:
	return clampf(float(danger - 1) / maxf(1.0, danger_max - 1.0), 0.0, 1.0)


# --- Cámara -----------------------------------------------------------------------------------

## Cambia el encuadre: la franja de la pregunta, la acción a pantalla completa o un primer plano.
func frame(shot: Shot, seconds: float = 0.6) -> void:
	_shot = shot
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
			return {"focus": _close_focus, "screen": Vector2(view.x * 0.5, view.y * 0.6), "zoom": 1.45}
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


# --- Ayudas -----------------------------------------------------------------------------------

func _make_avatar(scale_factor: float) -> AvatarCharacter:
	var avatar: AvatarCharacter = AVATAR.instantiate()
	avatar.scale = Vector2.ONE * scale_factor
	avatar.shadow_scale = 0.9
	avatar.interactive = true
	if look:
		avatar.apply(look)
	return avatar


## Antes de su primer acomodo la escena no tiene tamaño: no se dibuja nada.
func _has_room() -> bool:
	return size.x > 64.0 and size.y > 64.0


func _draw_sky(height: float) -> void:
	var colors := PackedColorArray([SKY_TOP, SKY_TOP, SKY_BOTTOM, SKY_BOTTOM])
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, height), Vector2(0, height)]), colors)


## Sol con rayos que giran despacio.
func _draw_sun(center: Vector2, radius: float) -> void:
	for i in 12:
		var angle := _time * 0.15 + TAU * i / 12.0
		var tip := center + Vector2.from_angle(angle) * radius * 1.7
		var left := center + Vector2.from_angle(angle - 0.12) * radius * 1.1
		var right := center + Vector2.from_angle(angle + 0.12) * radius * 1.1
		draw_colored_polygon(PackedVector2Array([left, tip, right]), Color(1.0, 0.86, 0.45, 0.45))
	draw_circle(center, radius * 1.15, Color(1.0, 0.93, 0.62, 0.5))
	draw_circle(center, radius, Color("#FFD35C"))


## Cerros lejanos con nieve, desplazados por `scroll` (se repiten sin costuras).
func _draw_far_peaks(base_y: float, height: float, scroll: float, color: Color, snow: bool) -> void:
	var points := PackedVector2Array([Vector2(0, base_y + 40)])
	var step := 8.0
	var x := 0.0
	while x <= size.x + step:
		var u := (x + scroll) * 0.0062
		var y := base_y - height * (0.55 + 0.25 * sin(u) + 0.15 * sin(u * 2.3 + 1.2) + 0.08 * sin(u * 5.1))
		points.append(Vector2(x, y))
		x += step
	points.append(Vector2(size.x, base_y + 40))
	draw_colored_polygon(points, color)
	if snow:
		for i in range(1, points.size() - 2):
			var p := points[i]
			if p.y < base_y - height * 0.82 and points[i - 1].y > p.y and points[i + 1].y >= p.y:
				draw_colored_polygon(PackedVector2Array([p + Vector2(-18, 14), p, p + Vector2(18, 14), p + Vector2(8, 10), p + Vector2(0, 16), p + Vector2(-8, 10)]), Color("#F7F9FB"))


## Lomas con andenes, desplazadas por `scroll`.
func _draw_hills(base_y: float, height: float, scroll: float, color: Color) -> void:
	var points := PackedVector2Array([Vector2(0, base_y + 60)])
	var x := 0.0
	while x <= size.x + 10.0:
		var u := (x + scroll) * 0.0105
		points.append(Vector2(x, base_y - height * (0.5 + 0.3 * sin(u + 0.4) + 0.2 * sin(u * 1.9))))
		x += 10.0
	points.append(Vector2(size.x, base_y + 60))
	draw_colored_polygon(points, color)
