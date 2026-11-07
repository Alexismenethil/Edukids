class_name FakeClock
extends Clock
## Reloj de prueba: marca la hora que la prueba decide y avanza a pedido.

## 7 de noviembre de 2026, 00:00:00 UTC.
var now := 1_794_009_600_000


func now_unix_ms() -> int:
	return now


func advance(milliseconds: int) -> void:
	now += milliseconds
