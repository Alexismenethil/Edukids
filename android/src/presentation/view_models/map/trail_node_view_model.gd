class_name TrailNodeViewModel
extends RefCounted
## Un nivel del sendero, con lo que muestra su ficha antes de jugar.

var package_id := ""
var level_id := ""
var title := ""
## «chase», «bridge», «caiman», «classic» o «final».
var mechanic: StringName = &""
var mechanic_name := ""
var mechanic_about := ""
var icon := ""
var details := ""
## «locked», «open» o «done».
var state: StringName = &"open"
var stars := 0
var final := false
var grade := ""
var grade_color := Color("#8C8079")
var badge := ""
var action_label := ""
var locked_text := ""
var attempts_text := ""
## false si está cerrado o si el desafío final ya no tiene intentos.
var playable := true
## Es el siguiente nivel sugerido del sendero.
var next := false
