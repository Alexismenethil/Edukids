class_name GodotRandomSource
extends RandomSource
## Adaptador de salida: aleatoriedad con RandomNumberGenerator.
## Con una semilla fija produce siempre la misma secuencia.

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value


func next_float() -> float:
	return _rng.randf()


func next_int(from_inclusive: int, to_inclusive: int) -> int:
	return _rng.randi_range(from_inclusive, to_inclusive)
