class_name TrailNodeResponse
extends RefCounted
## Un nivel dentro del sendero: si está abierto, sus estrellas y si quedó a medias.

var package_id := ""
var level_id := ""
var package_title := ""
var title := ""
var area: StringName = &""
var kind: StringName = &""
var mechanic: StringName = &""
var question_count := 0
var estimated_minutes := 0
var lives := 0
## «locked», «open» o «done» (TrailRule).
var state: StringName = &"open"
var best_stars := 0
var in_progress := false
## Desafío final: mejor calificación, intentos que quedan y cuántos hay.
var best_grade := ""
var attempts_left := 0
var max_attempts := 0
## Título del nivel que hay que completar para abrir este.
var unlocked_by := ""
