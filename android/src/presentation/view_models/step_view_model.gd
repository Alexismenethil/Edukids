class_name StepViewModel
extends RefCounted
## Una pregunta lista para la vista. `type` dice qué actividad mostrar y `data` trae lo que
## esa actividad necesita (opciones, afirmaciones, elementos, columnas, texto con espacios o teclado).

var question_id := ""
var type := ""
var prompt := ""
var image := ""
var counter := ""
var retry := false
var retry_label := ""
var tip := ""
var hint_available := false
var hint_label := ""
var check_label := ""
## Lo que dice el guía al ofrecer una pista (RF-26); vacío si no la ofrece.
var offer_text := ""
var progress: Array[StringName] = []
var index := 0
## Estímulo de la unidad de lectura (título, párrafos o tabla); vacío si no hay.
var unit := {}
var data := {}
var area: AreaViewModel
## Textos de las actividades: «Verdadero», «Falso», «Palabras», etc.
var labels := {}
