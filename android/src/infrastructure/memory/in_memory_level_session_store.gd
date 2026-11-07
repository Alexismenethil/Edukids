class_name InMemoryLevelSessionStore
extends LevelSessionStore
## Sesiones de nivel en curso, en memoria. Si el juego se cierra, StartLevel las rehace
## con las respuestas guardadas.

var _sessions := {}


func put(session: LevelSession) -> void:
	_sessions[session.attempt_id] = session


func find(attempt_id: String) -> LevelSession:
	return _sessions.get(attempt_id)


func remove(attempt_id: String) -> void:
	_sessions.erase(attempt_id)
