class_name ShortSelva
extends ShortScript
## Llegada a la Selva (capítulo 2): el avatar y Quwi entran al valle del Apurímac y los recibe
## Tunki, el gallito de las rocas, con su baile. Quwi le pasa la posta y vuelve a la Sierra.


func id() -> StringName:
	return &"selva"


func place() -> StringName:
	return &"jungle"


func beats() -> Array:
	return [
		{"cinema": true},
		{"cast": &"tunki", "at": [820], "facing": -1},
		{"cast": &"avatar", "at": [-200]},
		{"cast": &"quwi", "at": [-320]},
		{"shot": "wide", "time": 0.0},
		{"title": "La Selva", "subtitle": "Capítulo 2 · El valle del Apurímac", "time": 2.2, "join": true},
		{"together": [
			{"enter": &"avatar", "from": "left", "to": [470], "run": true, "speed": 1.3, "time": 2.0},
			{"enter": &"quwi", "from": "left", "to": [330], "hops": 5, "time": 2.2},
		]},
		{"look": &"avatar", "at": &"tunki"},
		{"look": &"quwi", "at": &"tunki"},
		{"shot": "action", "on": [640, 520], "zoom": 1.15, "time": 1.0, "join": true},
		{"play": &"tunki", "clip": &"dance"},
		{"fx": &"sparkles", "on": &"tunki", "offset": [0, -150], "radius": 90.0},
		{"say": &"tunki", "text": "¡Bienvenidos al valle del Apurímac! Soy Tunki, el gallito de las rocas.", "mood": &"cheer"},
		{"play": &"avatar", "clip": &"wave", "join": true},
		{"look": &"quwi", "at": &"avatar"},
		{"say": &"quwi", "text": "Tunki conoce cada rincón de la Selva. ¡Te dejo en buenas alas!", "mood": &"joy"},
		{"play": &"quwi", "clip": &"wave"},
		{"exit": &"quwi", "to": "left", "hops": 5, "time": 2.0, "join": true},
		{"play": &"tunki", "clip": &"show_off"},
		{"say": &"tunki", "text": "Aquí también cayeron nudos del quipu. ¡Sígueme por el río!", "mood": &"pride"},
		{"play": &"tunki", "clip": &"flutter", "join": true},
		{"play": &"avatar", "clip": &"celebrate"},
		{"shot": "wide", "time": 1.4, "join": true},
		{"turn": &"tunki", "facing": 1},
		{"together": [
			{"exit": &"tunki", "to": "right", "hops": 6, "time": 2.2},
			{"exit": &"avatar", "to": "right", "run": true, "speed": 1.5, "time": 2.4},
		]},
		{"cinema": false},
		{"wait": 0.3},
	]
