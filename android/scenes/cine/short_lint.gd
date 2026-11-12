class_name ShortLint
extends RefCounted
## Revisa el guion de un corto sin reproducirlo: verbos desconocidos, personajes que no están en el
## elenco, pasos que nombran a alguien que todavía no entró y acciones propias que no existen.
## Las pruebas lo corren sobre todo el catálogo, así un guion mal escrito se detecta enseguida.

const VERBS: Array[String] = ["wait", "together", "cast", "enter", "move", "exit", "play", "face", "emote", "look", "turn",
	"hop", "say", "shot", "fx", "shake", "punch", "flash", "hit_stop", "cinema", "light", "title", "sound", "call"]
## Verbos cuyo valor es el nombre de un personaje del corto.
const ACTOR_VERBS: Array[String] = ["enter", "move", "exit", "play", "face", "emote", "look", "turn", "hop", "say"]
const SHOTS: Array[String] = ["wide", "action", "close", "free"]
const EFFECTS: Array[StringName] = [&"puff", &"stars", &"sparkles", &"impact", &"ring", &"splash", &"hearts", &"leaves",
	&"streaks", &"confetti"]
const EMOTES: Array[StringName] = [&"heart", &"alert", &"question", &"note", &"idea", &"zzz", &"sweat", &"anger", &"dizzy",
	&"sparkle"]
const SOUNDS: Array[StringName] = [&"squeak", &"knots"]


## Problemas del guion, uno por línea. Vacío si está bien.
static func check(script: ShortScript) -> Array[String]:
	var problems: Array[String] = []
	var actors: Array[StringName] = []
	_check_list(script, script.beats(), actors, problems)
	return problems


static func _check_list(script: ShortScript, beats: Array, actors: Array[StringName], problems: Array[String]) -> void:
	for index in beats.size():
		if not beats[index] is Dictionary:
			problems.append("Paso %d: no es un diccionario." % index)
			continue
		var beat: Dictionary = beats[index]
		var verb := ""
		for candidate in VERBS:
			if beat.has(candidate):
				verb = candidate
				break
		if verb == "":
			problems.append("Paso %d: no tiene un verbo conocido (%s)." % [index, beat.keys()])
			continue
		match verb:
			"together":
				_check_list(script, beat["together"], actors, problems)
			"cast":
				var id: StringName = beat["cast"]
				if not Cast.ROSTER.has(id):
					problems.append("Paso %d: «%s» no está en el elenco." % [index, id])
				actors.append(beat.get("as", id))
			"shot":
				if not str(beat["shot"]) in SHOTS:
					problems.append("Paso %d: encuadre desconocido «%s»." % [index, beat["shot"]])
			"fx":
				if not StringName(beat["fx"]) in EFFECTS:
					problems.append("Paso %d: efecto desconocido «%s»." % [index, beat["fx"]])
			"emote":
				if not StringName(beat.get("kind", &"alert")) in EMOTES:
					problems.append("Paso %d: emote desconocido «%s»." % [index, beat["kind"]])
			"sound":
				if not StringName(beat["sound"]) in SOUNDS:
					problems.append("Paso %d: sonido desconocido «%s»." % [index, beat["sound"]])
			"call":
				if not script.has_method(str(beat["call"])):
					problems.append("Paso %d: el guion no tiene la acción «%s»." % [index, beat["call"]])
			"say":
				if str(beat.get("text", "")).strip_edges().is_empty():
					problems.append("Paso %d: el globo no tiene texto." % index)
			"play":
				if not beat.has("clip"):
					problems.append("Paso %d: falta el clip." % index)
		if verb in ACTOR_VERBS and not StringName(beat[verb]) in actors:
			problems.append("Paso %d: «%s» todavía no entró al corto (falta su paso cast)." % [index, beat[verb]])
		for key: String in ["on", "at"]:
			var target: Variant = beat.get(key)
			if verb != "cast" and (target is StringName or target is String) and not StringName(target) in actors:
				problems.append("Paso %d: «%s» apunta a «%s», que no está en el corto." % [index, key, target])
