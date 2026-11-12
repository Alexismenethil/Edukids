class_name ChapterMapViewModel
extends RefCounted
## Mapa del capítulo: saludo, estrellas reunidas y paradas en el orden del camino.

var chapter_name := ""
var chapter_title := ""
var greeting := ""
var stars_label := ""
var guide_line := ""
var look: AvatarLookViewModel
var edit_label := ""
var exit_label := ""
var stops: Array[StopPinViewModel] = []
## Parada donde está el avatar.
var current := 0
