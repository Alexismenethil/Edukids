class_name SystemClock
extends Clock
## Adaptador de salida: reloj del sistema operativo.


func now_unix_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
