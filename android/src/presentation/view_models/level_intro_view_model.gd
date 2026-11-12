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
## «chase», «bridge», «caiman» o «classic».
var mechanic: StringName = &"classic"
var mechanic_name := ""
## Desafío final: sin medidor, sin vidas y sin decir si cada respuesta está bien (RN-10).
var final := false
## Portada del desafío final (null si es práctica o si continúa un intento).
var cover: FinalCoverViewModel
var lives := 0
var lives_max := 0
var danger := 0
var danger_max := 0
## Capítulo del nivel (sierra, selva o costa): decide el mundo de la escena y quién lo guía.
var region: StringName = &"sierra"
## Guía del capítulo: su identificador en el elenco y su nombre visible.
var guide: StringName = &"quwi"
var guide_name := "Quwi"
## Aspecto del personaje del estudiante, para la escena de la mecánica.
var look: AvatarLookViewModel
var exit_detail := ""
var exit_confirm := ""
var exit_cancel := ""
