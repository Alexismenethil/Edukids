class_name DiagnosticsViewModel
extends RefCounted
## Datos fijos del panel de medición: versión, almacenamiento y tiempo de arranque.
## Las métricas en vivo (fps, memoria) las lee el propio panel del motor.

var version: String = ""
var storage: String = ""
## Milisegundos desde que arrancó el motor hasta que apareció la pantalla de inicio.
var startup_ms: int = 0
