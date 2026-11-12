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
var mechanic: StringName = &""
## Se acabaron las vidas (RN-14).
var game_over := false
var lives_left := 0
var lives_max := 0
var lives_lost := 0
var best_streak := 0
## Desafío final: calificación AD, A, B o C con su descripción, revisión de cada pregunta
## e intentos que quedan (RN-10 y RN-12).
var final := false
var grade := ""
var grade_description := ""
var review: Array[ReviewResponse] = []
var attempts_left := 0
var max_attempts := 0
## Estados de las preguntas, ya revelados (para el quipu de los resultados).
var progress: Array[StringName] = []
