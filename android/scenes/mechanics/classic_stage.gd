class_name ClassicStage
extends MechanicStage
## Mecánica clásica: se resuelven tarjetas con Quwi y Atoq se asoma por el costado derecho
## según el medidor de peligro. Lejos del peligro no se ve; muy cerca, mete la cabeza y una
## sonrisa pícara junto a la tarjeta (diseño del juego, capítulo 04).

const ATOQ_SCALE := 0.62

## Borde derecho de la pantalla y la altura de los pies de Atoq.
var foot_y := 560.0
var _atoq: AtoqCharacter
var _x := 0.0
var _x_target := 0.0


func _uses_world() -> bool:
	return false


func _ready() -> void:
	_atoq = AtoqCharacter.new()
	_atoq.scale = Vector2.ONE * ATOQ_SCALE
	_atoq.facing = -1
	_atoq.shadow_scale = 0.0
	_atoq.interactive = true
	add_child(_atoq)
	_x_target = _x_for(danger)
	_x = size.x + 200.0


func _x_for(value: int) -> float:
	var ratio := clampf(float(value - 1) / maxf(1.0, danger_max - 1.0), 0.0, 1.0)
	match 1 + int(round(ratio * 3.0)):
		1:
			return size.x - 30.0
		2:
			return size.x + 14.0
		3:
			return size.x + 58.0
	return size.x + 190.0


func start() -> void:
	_x_target = _x_for(danger)


func _process(delta: float) -> void:
	super(delta)
	_x = lerpf(_x, _x_target, minf(1.0, delta * 3.0))
	if _atoq:
		_atoq.position = Vector2(_x + sin(_time * 1.3) * 4.0, foot_y)


func react(feedback: FeedbackViewModel) -> float:
	danger = feedback.danger
	if feedback.correct:
		_atoq.surprise(0.6)
	else:
		_atoq.laugh(1.0)
	if feedback.life_lost:
		_x_target = size.x - 120.0
		var tween := create_tween()
		tween.tween_interval(0.5)
		tween.tween_callback(func() -> void:
			_atoq.lunge(30.0)
			StageFx.fly_knot(self, Vector2(size.x * 0.55, foot_y - 200.0), _atoq.position + Vector2(-20, -70),
				StageFx.KNOT_COLORS[randi() % StageFx.KNOT_COLORS.size()], 0.5))
		tween.tween_interval(0.6)
		tween.tween_callback(func() -> void: _atoq.laugh(1.4))
		tween.tween_interval(1.0)
		tween.tween_callback(func() -> void: _x_target = _x_for(danger))
		return 1.6
	_x_target = _x_for(danger)
	return 1.6


func play_payoff() -> void:
	_x_target = size.x + 220.0
	_atoq.play(&"grumble")
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(payoff_finished.emit)


func play_game_over() -> void:
	_x_target = size.x - 150.0
	_atoq.laugh(2.4)
	var tween := create_tween()
	tween.tween_interval(1.4)
	tween.tween_callback(payoff_finished.emit)
