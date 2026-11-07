class_name SessionStep
extends RefCounted
## Una pregunta en la fila del nivel. Si pertenece a una unidad de lectura, `unit` es esa unidad
## (su estímulo queda a la vista). `retry` indica que vuelve al final porque se falló (RF-29).

var item: Item
var unit: Item
var retry := false


func _init(question: Item = null, reading_unit: Item = null, is_retry: bool = false) -> void:
	item = question
	unit = reading_unit
	retry = is_retry
