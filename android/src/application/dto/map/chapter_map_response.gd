class_name ChapterMapResponse
extends RefCounted
## Mapa de un capítulo: sus paradas en el orden del camino y las estrellas reunidas.

var chapter: StringName = &""
var stops: Array[StopResponse] = []
var stars := 0
var max_stars := 0
