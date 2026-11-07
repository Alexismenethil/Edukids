class_name RequestHint
extends RefCounted
## Caso de uso: muestra la pista de la pregunta actual. Usarla no quita vidas, pero la pregunta
## deja de contar como acierto válido para las estrellas (RN-11).

var _sessions: LevelSessionStore


func _init(sessions: LevelSessionStore) -> void:
	_sessions = sessions


## Devuelve el texto de la pista, o "" si la pregunta no tiene.
func execute(attempt_id: String) -> String:
	var session := _sessions.find(attempt_id)
	return session.take_hint() if session else ""
