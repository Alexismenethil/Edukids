class_name ShortRope
extends ShortScript
## Una cuerda vuelve al quipu: después de superar un desafío final, el avatar y Quwi regresan de
## noche a Huamanga y le entregan a Mama Sisa el nudo recuperado. Kuntur cruza el cielo.
## Parámetros: "text" (qué cuerda se recuperó) y "color" (el color del área).

var _quipu: QuipuProp
var _knot: KnotSprite


func id() -> StringName:
	return &"rope"


func mood() -> StringName:
	return &"night"


func setup() -> void:
	WorldSets.fiesta(player.track, player.ground_y, -260.0, 1640.0)


func beats() -> Array:
	var text: String = params.get("text", "¡Recuperaste una cuerda del quipu!")
	return [
		{"cinema": true},
		{"cast": &"sisa", "at": [760], "facing": -1},
		{"cast": &"condor", "at": [1500, 250], "scale": 0.34, "behind": true},
		{"cast": &"avatar", "at": [-200]},
		{"cast": &"quwi", "at": [-320]},
		{"call": "hold_quipu"},
		{"shot": "wide", "time": 0.0},
		{"move": &"condor", "to": [-300, 210], "time": 9.0, "face_travel": false, "join": true},
		{"together": [
			{"enter": &"avatar", "from": "left", "to": [520], "run": true, "speed": 1.4, "time": 1.8},
			{"enter": &"quwi", "from": "left", "to": [390], "hops": 5, "time": 2.0},
		]},
		{"shot": "action", "on": [620, 520], "zoom": 1.18, "time": 1.0, "join": true},
		{"play": &"sisa", "clip": &"wave", "join": true},
		{"look": &"avatar", "at": &"sisa"},
		{"look": &"quwi", "at": &"sisa"},
		{"call": "show_knot"},
		{"play": &"avatar", "clip": &"celebrate"},
		{"call": "deliver_knot", "time": 0.75},
		{"sound": &"knots"},
		{"flash": "#FFF2C0", "alpha": 0.4},
		{"punch": 0.06},
		{"fx": &"ring", "on": &"sisa", "offset": [-4, -110], "size": 44.0},
		{"fx": &"sparkles", "on": &"sisa", "offset": [-4, -110], "amount": 16, "radius": 130.0},
		{"fx": &"stars", "on": &"sisa", "offset": [-4, -90], "amount": 10},
		{"play": &"sisa", "clip": &"present", "join": true},
		{"light": "#FFF1DC", "time": 1.0},
		{"say": &"sisa", "text": text + " El quipu vuelve a recordar.", "mood": &"joy"},
		{"fx": &"confetti"},
		{"play": &"quwi", "clip": &"celebrate", "join": true},
		{"play": &"avatar", "clip": &"dance", "join": true},
		{"play": &"sisa", "clip": &"clap"},
		{"say": &"quwi", "text": "¡Todavía faltan nudos por encontrar! ¿Seguimos?", "mood": &"cheer"},
		{"play": &"avatar", "clip": &"flip", "join": true},
		{"shot": "wide", "time": 1.4},
		{"cinema": false},
		{"wait": 0.3},
	]


## Mama Sisa espera con el quipu sin nudos.
func hold_quipu() -> void:
	_quipu = QuipuProp.new()
	_quipu.scale = Vector2.ONE * 0.62
	_quipu.knotted = false
	player.actors.add_child(_quipu)
	_quipu.hold(player.actor(&"sisa"), Vector2(-4.0, -92.0))


## El avatar levanta el nudo que recuperó.
func show_knot() -> void:
	var avatar := player.actor(&"avatar")
	_knot = KnotSprite.new()
	_knot.color = Color(str(params.get("color", "#E8833A")))
	_knot.radius = 15.0
	_knot.position = avatar.position + Vector2(0.0, -250.0)
	player.actors.add_child(_knot)
	ToonFx.sparkles(player.actors, _knot.position, 8, 50.0)


## El nudo vuela en arco hasta el quipu y lo completa.
func deliver_knot() -> void:
	var from := _knot.position
	var to := _quipu.position + Vector2(0.0, 30.0)
	var tween := _knot.create_tween()
	tween.tween_method(func(t: float) -> void:
		var peak := Vector2((from.x + to.x) * 0.5, minf(from.y, to.y) - 110.0)
		_knot.position = from.lerp(peak, t).lerp(peak.lerp(to, t), t)
		_knot.rotation = t * TAU, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		_knot.queue_free()
		_quipu.knotted = true)
