class_name DialogueViewModel
extends RefCounted
## Una escena de diálogo lista para mostrarse.

var lines: Array[DialogueLineViewModel] = []
var next_label: String = "Seguir"
var skip_label: String = "Saltar"
var close_label: String = "¡Vamos!"
