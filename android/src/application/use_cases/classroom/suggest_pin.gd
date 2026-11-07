class_name SuggestPin
extends RefCounted
## Caso de uso: propone un PIN de 4 números al azar para un estudiante, que no sea una serie
## fácil de adivinar (1111, 1234). El docente puede usarlo o escribir otro.

const MAX_TRIES := 64

var _random: RandomSource


func _init(random: RandomSource) -> void:
	_random = random


func execute() -> String:
	var digits := ""
	for attempt in MAX_TRIES:
		digits = ""
		for position in Pin.STUDENT_LENGTH:
			digits += str(_random.next_int(0, 9))
		if not Pin.is_easy_to_guess(digits):
			return digits
	return digits
