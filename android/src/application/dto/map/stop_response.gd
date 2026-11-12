class_name StopResponse
extends RefCounted
## Una parada del mapa: sin paquetes habilitados aparece con candado (RN-01).

var id := ""
var available := false
var trails: Array[TrailResponse] = []
var stars := 0
var max_stars := 0
## Desafíos finales completados en la parada (cuerdas recuperadas).
var cords := 0
