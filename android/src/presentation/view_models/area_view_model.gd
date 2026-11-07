class_name AreaViewModel
extends RefCounted
## Cómo se ve un área: nombre, color, tono oscuro para texto blanco e icono.

var name := ""
var color := Color("#1F7A70")
var deep := Color("#1F7A70")
var icon := ""


static func of(area: StringName) -> AreaViewModel:
	var view_model := AreaViewModel.new()
	view_model.name = AreaPalette.name_of(area)
	view_model.color = AreaPalette.color_of(area)
	view_model.deep = AreaPalette.deep_of(area)
	view_model.icon = AreaPalette.icon_of(area)
	return view_model
