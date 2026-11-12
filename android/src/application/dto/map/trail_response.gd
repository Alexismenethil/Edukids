class_name TrailResponse
extends RefCounted
## Sendero de un área en una parada: sus niveles en orden, con el desafío final al final.

var area: StringName = &""
var nodes: Array[TrailNodeResponse] = []
var stars := 0
var max_stars := 0
