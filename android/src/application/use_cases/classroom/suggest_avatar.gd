class_name SuggestAvatar
extends RefCounted
## Caso de uso: arma un personaje al azar para el botón «Sorpréndeme» del editor.
## La ropa de arriba y la de abajo nunca salen del mismo color.

var _random: RandomSource


func _init(random: RandomSource) -> void:
	_random = random


## Con body vacío también elige al azar entre niña y niño.
func execute(body: StringName = &"") -> Dictionary:
	var chosen := body if body in Avatar.BODIES else Avatar.BODIES[_random.next_int(0, Avatar.BODIES.size() - 1)]
	var traits := {"body": String(chosen)}
	var counts := Avatar.option_counts()
	for trait_name: String in counts:
		traits[trait_name] = _random.next_int(0, counts[trait_name] - 1)
	if traits["top_color"] == traits["bottom_color"]:
		traits["bottom_color"] = (traits["bottom_color"] + 3) % Avatar.OUTFIT_COLORS
	return traits
