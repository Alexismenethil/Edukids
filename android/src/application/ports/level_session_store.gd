@abstract class_name LevelSessionStore
extends RefCounted
## Puerto: sesiones de nivel en curso mientras el juego está abierto. Si la aplicación se cierra,
## la sesión se rehace con las respuestas guardadas.


@abstract func put(session: LevelSession) -> void


@abstract func find(attempt_id: String) -> LevelSession


@abstract func remove(attempt_id: String) -> void
