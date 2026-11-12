class_name ShortCosta
extends ShortScript
## Llegada a la Costa (capítulo 3): al atardecer, el avatar y Tunki llegan a la playa y Humbi, el
## pingüino de Humboldt, aparece deslizándose de panza. Tunki le pasa la posta y vuelve a la Selva.


func id() -> StringName:
	return &"costa"


func place() -> StringName:
	return &"coast"


func mood() -> StringName:
	return &"dusk"


func beats() -> Array:
	return [
		{"cinema": true},
		{"cast": &"humbi", "at": [1600], "facing": -1, "hidden": true},
		{"cast": &"avatar", "at": [-200]},
		{"cast": &"tunki", "at": [-320]},
		{"shot": "wide", "time": 0.0},
		{"title": "La Costa", "subtitle": "Capítulo 3 · Del mar al desierto", "time": 2.2, "join": true},
		{"together": [
			{"enter": &"avatar", "from": "left", "to": [470], "run": true, "speed": 1.3, "time": 2.0},
			{"enter": &"tunki", "from": "left", "to": [330], "hops": 5, "time": 2.2},
		]},
		{"shot": "action", "on": [640, 520], "zoom": 1.15, "time": 1.0, "join": true},
		{"enter": &"humbi", "from": "right", "to": [840], "time": 1.5},
		{"play": &"humbi", "clip": &"slide", "join": true},
		{"fx": &"puff", "on": &"humbi", "offset": [40, -6], "amount": 8},
		{"together": [
			{"emote": &"avatar", "kind": &"alert"},
			{"look": &"avatar", "at": &"humbi"},
			{"look": &"tunki", "at": &"humbi"},
			{"wait": 1.3},
		]},
		{"play": &"humbi", "clip": &"tip_hat", "join": true},
		{"say": &"humbi", "text": "¡Hola! Soy Humbi. Bienvenidos a la Costa, donde el desierto se encuentra con el mar.", "mood": &"joy"},
		{"play": &"avatar", "clip": &"wave", "join": true},
		{"look": &"tunki", "at": &"avatar"},
		{"say": &"tunki", "text": "Humbi es el mejor nadador del Pacífico. ¡Buen viaje!", "mood": &"cheer"},
		{"play": &"tunki", "clip": &"flutter"},
		{"exit": &"tunki", "to": "left", "hops": 5, "time": 2.0, "join": true},
		{"play": &"humbi", "clip": &"flap"},
		{"say": &"humbi", "text": "Los nudos brillan entre las olas y la arena. ¡Vamos a buscarlos!", "mood": &"pride"},
		{"play": &"avatar", "clip": &"celebrate"},
		{"shot": "wide", "time": 1.4, "join": true},
		{"turn": &"humbi", "facing": 1},
		{"together": [
			{"exit": &"humbi", "to": "right", "time": 2.6, "run": true, "speed": 1.2},
			{"exit": &"avatar", "to": "right", "run": true, "speed": 1.4, "time": 2.6},
		]},
		{"cinema": false},
		{"wait": 0.3},
	]
