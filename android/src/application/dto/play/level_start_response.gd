class_name LevelStartResponse
extends RefCounted
## Un nivel que empieza o que continúa donde se quedó (RF-14).

var attempt_id := ""
var title := ""
var package_title := ""
var area: StringName = &""
var kind: StringName = &""
var mechanic: StringName = &""
var guide_intro: Array[String] = []
var total := 0
var resumed := false
## Preguntas ya respondidas al continuar.
var answered := 0
## Primera pregunta por responder, o null si ya se respondió todo.
var step: StepResponse
## Desafío final: sin medidor, sin vidas y sin retroalimentación hasta el final (RN-10).
var final := false
## En el desafío final: número de este intento y cuántos hay.
var attempt_number := 1
var max_attempts := 0
var lives := 0
var lives_max := 0
var danger := 0
var danger_max := 0
var streak := 0
