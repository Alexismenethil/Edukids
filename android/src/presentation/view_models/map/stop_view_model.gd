class_name StopViewModel
extends RefCounted
## Una parada: su escena, el saludo del guía y un sendero por área.

var id := ""
var name := ""
var about := ""
var guide: DialogueViewModel
var back_label := ""
var stars_label := ""
var trails: Array[TrailViewModel] = []
var look: AvatarLookViewModel
