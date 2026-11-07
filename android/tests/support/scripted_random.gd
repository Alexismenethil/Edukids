class_name ScriptedRandom
extends RandomSource
## Aleatoriedad de prueba: devuelve en orden los valores indicados y vuelve a empezar.

var _values: Array[int] = []
var _index := 0


func _init(values: Array[int] = [0]) -> void:
	_values = values


func next_float() -> float:
	return 0.5


func next_int(from_inclusive: int, to_inclusive: int) -> int:
	var value := _values[_index % _values.size()]
	_index += 1
	return clampi(value, from_inclusive, to_inclusive)
