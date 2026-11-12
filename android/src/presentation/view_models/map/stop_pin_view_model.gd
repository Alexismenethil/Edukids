class_name StopPinViewModel
extends RefCounted
## Una parada en el mapa del capítulo.

var id := ""
var name := ""
var about := ""
var icon := ""
var available := false
var locked_text := ""
var stars := 0
var max_stars := 0
var stars_label := ""
## Cuerdas del quipu recuperadas en la parada (desafíos finales completados).
var cords := 0
## Colores de las áreas que tienen sendero en la parada.
var colors: Array[Color] = []
