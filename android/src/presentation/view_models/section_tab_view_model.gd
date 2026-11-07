class_name SectionTabViewModel
extends RefCounted
## Una sección para elegir: «6.° A».

var id := ""
var label := ""


static func create(section_id: String, text: String) -> SectionTabViewModel:
	var tab := SectionTabViewModel.new()
	tab.id = section_id
	tab.label = text
	return tab
