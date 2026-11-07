class_name LevelIntroViewModel
extends RefCounted
## Lo necesario para abrir un nivel: título, área, el saludo del guía y la primera pregunta.

## Mensaje si el nivel no se pudo abrir; vacío si todo está bien.
var error := ""
var title := ""
var area: AreaViewModel
var exit_label := ""
var dialogue: DialogueViewModel
var total := 0
## null si ya se respondió todo (el intento quedó abierto justo al final).
var step: StepViewModel
var exit_question := ""
var exit_detail := ""
var exit_confirm := ""
var exit_cancel := ""
