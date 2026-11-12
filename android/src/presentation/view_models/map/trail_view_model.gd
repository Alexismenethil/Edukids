class_name TrailViewModel
extends RefCounted
## Sendero de un área: una cuerda del quipu con un nudo por nivel.

var area: AreaViewModel
var title := ""
var stars_label := ""
var nodes: Array[TrailNodeViewModel] = []
