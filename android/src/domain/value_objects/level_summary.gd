class_name LevelSummary
extends RefCounted
## Resumen de un nivel (RF-14): aciertos, aciertos válidos, pistas, vidas y estrellas.
## En el desafío final, además, la calificación AD, A, B o C (RN-12) y no hay estrellas.

var total := 0
## Preguntas acertadas al primer intento (con o sin pista).
var correct := 0
## Aciertos válidos: al primer intento y sin pista (RN-11).
var valid_hits := 0
## Preguntas falladas que se corrigieron en el repaso final (no suman estrellas).
var fixed := 0
var hints_used := 0
var lives_lost := 0
var lives_left := 0
## El nivel terminó porque se acabaron las vidas.
var game_over := false
## Desafío final: sin medidor, sin vidas y con calificación.
var final := false
## Calificación del desafío final, o null en la práctica.
var grade: CnebGrade
## La racha más larga de aciertos seguidos.
var best_streak := 0
## Tiempo respondiendo, sin contar la lectura de la retroalimentación.
var time_ms := 0
var percent := 0.0
var stars := 0
var completed := false
