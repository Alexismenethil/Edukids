@abstract class_name Clock
extends RefCounted
## Puerto: hora actual. Con un reloj falso, las pruebas siempre dan el mismo resultado.


## Milisegundos desde el 1 de enero de 1970 (UTC).
@abstract func now_unix_ms() -> int
