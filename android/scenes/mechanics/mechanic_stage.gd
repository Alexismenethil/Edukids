@abstract class_name MechanicStage
extends CineStage
## Escena de una mecánica de juego (diseño del juego, capítulo 04): un mundo a pantalla completa
## con cámara. Mientras se responde, la cámara encuadra la franja de arriba de la tarjeta; al
## responder, la tarjeta baja y la cámara abre a toda la pantalla para que la reacción se vea en
## grande (acierto, error o vida perdida). Todas las mecánicas comparten la regla del dominio (el
## medidor de peligro y las vidas); solo cambia cómo se ve.

## Terminó el final feliz (o el game over): ya se pueden mostrar los resultados.
signal payoff_finished
## El peligro alcanzó al avatar: es el momento de romper un corazón.
signal life_taken

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const SKY_TOP := Color("#5DB6E6")
const SKY_BOTTOM := Color("#CFEFF8")

var area: AreaViewModel
var look: AvatarLookViewModel
var total := 0
var danger := 2
var danger_max := 4
var progress: Array[StringName] = []
## Capítulo del nivel: las mecánicas que corren usan el mundo de su región (WorldSets).
var region: StringName = &"sierra"


func configure(intro: LevelIntroViewModel) -> void:
	area = intro.area
	look = intro.look
	total = intro.total
	danger = intro.danger
	danger_max = maxi(1, intro.danger_max)
	region = intro.region
	if intro.step:
		progress = intro.step.progress
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if _uses_world():
		open_world()


func _uses_world() -> bool:
	return true


## Entrada de la escena al abrir el nivel.
func start() -> void:
	pass


## Llega una pregunta nueva. La luz acompaña el avance: el nivel empieza de día y termina dorado.
func question_shown(step: StepViewModel) -> void:
	progress = step.progress
	light(journey_light(), 1.6)


## Luz del mundo según cuánto falta: blanca al empezar y cálida al acercarse el final.
func journey_light() -> Color:
	var answered := 0
	for state in progress:
		if state != &"" and state != &"pending" and state != &"current":
			answered += 1
	var advance := clampf(float(answered) / maxf(1.0, progress.size()), 0.0, 1.0)
	return Color.WHITE.lerp(Color(1.0, 0.93, 0.83), advance * advance)


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
