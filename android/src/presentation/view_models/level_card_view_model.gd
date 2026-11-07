class_name LevelCardViewModel
extends RefCounted
## Tarjeta de un nivel en el inicio del estudiante.

var package_id := ""
var level_id := ""
var title := ""
var details := ""
var area: AreaViewModel
var stars := 0
var action_label := ""
## «A medias» si dejó el nivel sin terminar; vacío si no.
var badge := ""
