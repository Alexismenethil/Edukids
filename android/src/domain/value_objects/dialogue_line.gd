class_name DialogueLine
extends RefCounted
## Un globo de diálogo: quién habla, qué dice y con qué expresión.
## Como no hay voces, cada globo es breve: una o dos líneas.
## La señal (cue) es opcional y activa un efecto de la escena, por ejemplo "knots_scatter".

const MAX_TEXT_LENGTH := 120

## Expresiones de los guías (ver docs/05-diseno-del-juego/02-personajes.md).
const MOODS: Array[StringName] = [&"joy", &"cheer", &"think", &"surprise", &"pride", &"comfort"]

var speaker: StringName:
	get:
		return _speaker

var text: String:
	get:
		return _text

var mood: StringName:
	get:
		return _mood

var cue: StringName:
	get:
		return _cue

var _speaker: StringName
var _text: String
var _mood: StringName
var _cue: StringName


func _init(line_speaker: StringName, line_text: String, line_mood: StringName = &"joy", line_cue: StringName = &"") -> void:
	_speaker = line_speaker
	_text = line_text.strip_edges()
	_mood = line_mood
	_cue = line_cue


## Crea un globo validando el hablante, la longitud, la expresión y la señal.
static func create(line_speaker: StringName, line_text: String, line_mood: StringName = &"joy", line_cue: StringName = &"") -> Result:
	if String(line_speaker).is_empty():
		return Result.fail(&"missing_speaker", "Cada globo necesita a alguien que hable.")
	var clean_text := line_text.strip_edges()
	if clean_text.is_empty():
		return Result.fail(&"empty_text", "Un globo no puede estar vacío.")
	if clean_text.length() > MAX_TEXT_LENGTH:
		return Result.fail(&"text_too_long", "Un globo admite hasta %d caracteres." % MAX_TEXT_LENGTH)
	if not MOODS.has(line_mood):
		return Result.fail(&"unknown_mood", "Expresión desconocida: %s." % line_mood)
	if not String(line_cue).is_valid_ascii_identifier() and not String(line_cue).is_empty():
		return Result.fail(&"invalid_cue", "La señal debe ser un identificador: %s." % line_cue)
	return Result.ok(DialogueLine.new(line_speaker, clean_text, line_mood, line_cue))
