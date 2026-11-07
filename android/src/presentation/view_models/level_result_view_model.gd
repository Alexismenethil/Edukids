class_name LevelResultViewModel
extends RefCounted
## Resultados de un nivel: estrellas, aciertos y lo que dice el guía (RF-14 y RF-25).

var heading := ""
var title := ""
var stars := 0
var new_record := false
var record_label := ""
var lines: Array[String] = []
var guide_line := ""
var area: AreaViewModel
var progress: Array[StringName] = []
var replay_label := ""
var continue_label := ""
var warning := ""
