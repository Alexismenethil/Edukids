class_name ShortPrologue
extends ShortScript
## Prólogo: la fiesta en Huamanga. Mama Sisa muestra el quipu de los saberes, Atoq lo jala por
## travesura y los nudos salen volando por la Sierra, la Selva y la Costa. Quwi y el avatar salen
## a buscarlos. Cuatro globos de diálogo, como pide el diseño narrativo.

var _quipu: QuipuProp


func id() -> StringName:
	return &"prologue"


func mood() -> StringName:
	return &"dusk"


func setup() -> void:
	WorldSets.fiesta(player.track, player.ground_y, -260.0, 1640.0)


func beats() -> Array:
	return [
		{"cinema": true},
		{"cast": &"sisa", "at": [690], "facing": -1},
		{"cast": &"quwi", "at": [430]},
		{"cast": &"avatar", "at": [300]},
		{"cast": &"atoq", "at": [1700], "facing": -1, "hidden": true},
		{"call": "hold_quipu"},
		{"look": &"quwi", "at": &"sisa"},
		{"look": &"avatar", "at": &"sisa"},
		{"shot": "wide", "time": 0.0},
		{"title": "El quipu de los saberes", "subtitle": "Prólogo · Fiesta en Huamanga", "time": 2.4},
		{"shot": "action", "on": [560, 520], "zoom": 1.12, "time": 1.4, "join": true},
		{"play": &"sisa", "clip": &"present", "join": true},
		{"fx": &"sparkles", "on": &"sisa", "offset": [-10, -150], "radius": 110.0},
		{"say": &"sisa", "text": "¡Bienvenidos a la fiesta! Este quipu guarda en sus nudos los saberes de nuestro pueblo.", "mood": &"joy"},
		{"play": &"quwi", "clip": &"celebrate", "join": true},
		{"play": &"avatar", "clip": &"clap"},
		# Atoq se acerca agazapado por detrás.
		{"shot": "free", "on": [1000, 540], "zoom": 1.2, "time": 1.0, "join": true},
		{"enter": &"atoq", "from": "right", "to": [1060], "time": 1.3, "run": true, "speed": 0.8},
		{"play": &"atoq", "clip": &"sneak", "join": true},
		{"emote": &"atoq", "kind": &"idea"},
		{"wait": 1.1},
		{"together": [
			{"emote": &"quwi", "kind": &"alert"},
			{"face": &"quwi", "is": &"wow", "time": 2.0},
			{"look": &"quwi", "at": &"atoq"},
			{"look": &"avatar", "at": &"atoq"},
			{"shot": "action", "on": [700, 520], "zoom": 1.05, "time": 0.5},
		]},
		# El jalón.
		{"move": &"atoq", "to": [840], "time": 0.34, "run": true, "speed": 2.0},
		{"call": "snatch"},
		{"hit_stop": 0.09},
		{"shake": 9.0},
		{"flash": "#FFF6D8", "alpha": 0.45},
		{"punch": 0.07},
		{"fx": &"impact", "on": &"sisa", "offset": [60, -140], "size": 52.0},
		{"play": &"sisa", "clip": &"gasp", "join": true},
		{"play": &"avatar", "clip": &"startle", "join": true},
		{"sound": &"knots"},
		{"call": "scatter_knots"},
		{"shot": "wide", "on": [640, 420], "time": 0.9, "join": true},
		{"look": &"sisa", "at": [700, 0]},
		{"look": &"quwi", "at": [500, 0]},
		{"look": &"avatar", "at": [400, 0]},
		{"wait": 0.9},
		{"turn": &"atoq", "facing": 1},
		{"call": "laugh_and_run"},
		{"exit": &"atoq", "to": "right", "run": true, "speed": 1.9, "time": 1.3},
		{"light": "#E9E2F4", "time": 0.8},
		{"shot": "action", "on": [600, 520], "zoom": 1.15, "time": 0.9, "join": true},
		{"look": &"sisa", "at": &"quwi"},
		{"say": &"sisa", "text": "¡Ay, Atoq travieso! Sin esos nudos olvidaremos cómo contar, leer y cuidar la naturaleza.", "mood": &"sad"},
		{"look": &"quwi", "at": &"avatar"},
		{"play": &"quwi", "clip": &"ponder", "join": true},
		{"say": &"quwi", "text": "¡Volaron por la Sierra, la Selva y la Costa! ¿Vamos juntos a recuperarlos?", "mood": &"think"},
		{"look": &"avatar", "at": null},
		{"face": &"avatar", "is": &"determined", "time": 1.2},
		{"play": &"avatar", "clip": &"celebrate", "join": true},
		{"fx": &"stars", "on": &"avatar", "offset": [0, -30]},
		{"light": "#FFFFFF", "time": 1.0},
		{"play": &"quwi", "clip": &"celebrate"},
		{"look": &"sisa", "at": &"avatar"},
		{"play": &"sisa", "clip": &"nod", "join": true},
		{"say": &"sisa", "text": "Cuento con ustedes, pequeños guardianes. ¡Buen viaje!", "mood": &"happy"},
		{"play": &"sisa", "clip": &"wave", "join": true},
		{"shot": "wide", "time": 1.6, "join": true},
		{"together": [
			{"exit": &"avatar", "to": "right", "run": true, "speed": 1.5, "time": 2.2},
			{"exit": &"quwi", "to": "right", "hops": 7, "time": 2.4},
		]},
		{"cinema": false},
		{"wait": 0.4},
	]


## Mama Sisa sostiene el quipu frente a su pollera.
func hold_quipu() -> void:
	_quipu = QuipuProp.new()
	_quipu.scale = Vector2.ONE * 0.62
	player.actors.add_child(_quipu)
	_quipu.hold(player.actor(&"sisa"), Vector2(-4.0, -92.0))


## Atoq se lleva la cuerda madre en el hocico.
func snatch() -> void:
	var atoq := player.actor(&"atoq")
	_quipu.flutter = 3.0
	_quipu.hold(atoq, Vector2(96.0 * atoq.facing, -86.0))


## Los nudos salen volando en todas direcciones y se pierden en el cielo.
func scatter_knots() -> void:
	var points := _quipu.knot_points()
	_quipu.knotted = false
	var center := _quipu.position
	ToonFx.ring(player.actors, center, 40.0, Color(1.0, 0.92, 0.6, 0.9), 1.0, 3.4, 0.6)
	ToonFx.sparkles(player.actors, center, 16, 150.0)
	for index in points.size():
		var from := points[index]
		var angle := -PI * 0.5 + (float(index) / maxf(1.0, points.size() - 1.0) - 0.5) * 2.6
		var to := center + Vector2.from_angle(angle) * randf_range(900.0, 1150.0)
		StageFx.fly_knot(player.actors, from, to, _quipu.knot_color(index), randf_range(1.5, 2.2))


func laugh_and_run() -> void:
	var atoq := player.actor(&"atoq") as AtoqCharacter
	_quipu.hold(atoq, Vector2(96.0, -86.0))
	atoq.laugh(1.2)
	atoq.emote(&"note", 1.0)
