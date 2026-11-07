class_name DialogueLineViewModel
extends RefCounted
## Un globo listo para mostrarse: nombre visible, texto, expresión y señal de efecto.

var speaker_name: String
var text: String
var mood: StringName
var cue: StringName


func _init(line_speaker_name: String, line_text: String, line_mood: StringName, line_cue: StringName = &"") -> void:
	speaker_name = line_speaker_name
	text = line_text
	mood = line_mood
	cue = line_cue
