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
var mechanic: StringName = &"classic"
var lives_left := 0
var lives_max := 0
## Se acabaron las vidas: Atoq (o Coco, o el río) se quedó con los nudos.
var game_over := false
var game_over_message := ""
## Desafío final: calificación, porcentaje, cuerda del quipu y revisión de cada pregunta.
var final := false
var grade := ""
var grade_description := ""
var grade_color := Color.WHITE
var percent_label := ""
var cord_label := ""
var golden_knot := false
var attempts_label := ""
var review_title := ""
var review: Array[ReviewItemViewModel] = []
## false si ya no quedan intentos para repetir.
var can_replay := true
