@abstract class_name RandomSource
extends RefCounted
## Puerto: aleatoriedad para ordenar preguntas y opciones de forma reproducible en las pruebas.


## Número decimal entre 0 y 1.
@abstract func next_float() -> float


## Número entero entre from_inclusive y to_inclusive.
@abstract func next_int(from_inclusive: int, to_inclusive: int) -> int
