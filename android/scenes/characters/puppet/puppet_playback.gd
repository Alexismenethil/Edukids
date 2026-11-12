class_name PuppetPlayback
extends RefCounted
## Un clip que está sonando en un títere. Sirve para esperarlo (`await playback.finished`) o para
## cortarlo antes (`stop`).

## El clip terminó o lo cortaron.
signal finished

var clip: PuppetClip
var time := 0.0
var speed := 1.0
## Cuánto pesa el clip (1 = completo; más de 1 lo exagera).
var amount := 1.0
var loop := false
## Peso actual (sube con la entrada y baja con la salida).
var weight := 0.0
## Expresión que el clip tiene puesta en la cara (vacía si ninguna).
var face: StringName = &""
var done := false

var _fade_out := -1.0
var _fade_left := 0.0
var _next_event := 0


func _init(source: PuppetClip = null) -> void:
	clip = source
	if clip:
		loop = clip.loop
		weight = 0.0 if clip.fade_in > 0.0 else 1.0


## Apaga el clip suavemente.
func stop(fade: float = 0.14) -> void:
	if done or _fade_out >= 0.0:
		return
	_fade_out = maxf(fade, 0.0001)
	_fade_left = _fade_out


## Avanza el clip. Devuelve los eventos que tocan en este cuadro: [pista, valor].
func advance(delta: float) -> Array:
	var fired: Array = []
	if done or clip == null:
		return fired
	time += delta * speed
	while _next_event < clip.events.size() and clip.events[_next_event][0] <= time:
		var event: Array = clip.events[_next_event]
		_next_event += 1
		if event[1] == "face":
			face = StringName(event[2])
		else:
			fired.append([event[1], event[2]])
	if time >= clip.length:
		if loop and clip.length > 0.0:
			time = fposmod(time, clip.length)
			_next_event = 0
		elif _fade_out < 0.0:
			stop(clip.fade_out)
	if _fade_out >= 0.0:
		_fade_left -= delta
		weight = clampf(_fade_left / _fade_out, 0.0, 1.0)
		if _fade_left <= 0.0:
			_finish()
	elif clip.fade_in > 0.0:
		weight = minf(1.0, weight + delta / clip.fade_in)
	else:
		weight = 1.0
	return fired


func _finish() -> void:
	if done:
		return
	done = true
	weight = 0.0
	face = &""
	finished.emit()
