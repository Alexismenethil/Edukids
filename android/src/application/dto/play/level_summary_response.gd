class_name LevelSummaryResponse
extends RefCounted
## Resultado de un nivel terminado (RF-14 y RF-25).

var title := ""
var area: StringName = &""
var total := 0
var correct := 0
var valid_hits := 0
var fixed := 0
var hints_used := 0
var percent := 0.0
var stars := 0
var time_ms := 0
## Mejores estrellas que tenía antes de este intento.
var best_before := 0
var saved := true
