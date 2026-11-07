class_name StudentHomeViewModel
extends RefCounted
## Inicio del estudiante: su personaje, Quwi y los niveles para practicar mientras llega el mapa.

var greeting := ""
var message := ""
var levels_title := ""
var levels: Array[LevelCardViewModel] = []
var look: AvatarLookViewModel
var edit_label := ""
var exit_label := ""
