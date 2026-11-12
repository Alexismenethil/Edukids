class_name PackagesPresenter
extends RefCounted
## Presentador de «Paquetes» en el modo docente: los paquetes de la tablet con su habilitación por
## sección (RF-09) y la importación de un paquete copiado por USB o por cable (RF-19).

const IMPORT_FOLDER := "Download/EduKids"

var _list: ListPackages
var _set_access: SetPackageAccess
var _imports: ListImportFiles
var _install: InstallPackage


func _init(list_packages: ListPackages, set_access: SetPackageAccess, list_imports: ListImportFiles, install: InstallPackage) -> void:
	_list = list_packages
	_set_access = set_access
	_imports = list_imports
	_install = install


func cards(section_id: String, section_label: String) -> Array[PackageCardViewModel]:
	var cards: Array[PackageCardViewModel] = []
	for row in _list.execute(section_id):
		var card := PackageCardViewModel.new()
		card.id = row.id
		card.title = row.title
		var parts: Array[String] = [AreaPalette.name_of(row.area)]
		if row.kind == &"module" and row.number > 0:
			parts.append("Módulo %d" % row.number)
		elif row.kind == &"challenge":
			parts.append("Reto del docente")
		parts.append("%d %s" % [row.level_count, "nivel" if row.level_count == 1 else "niveles"])
		parts.append("versión %s" % row.version)
		card.detail = " · ".join(parts)
		card.origin = "Viene con el juego" if row.bundled else "Instalado en la tablet"
		card.icon = AreaPalette.icon_of(row.area)
		card.color = AreaPalette.color_of(row.area)
		card.enabled = row.enabled
		card.enabled_label = ("Habilitado para %s" if row.enabled else "Habilitar para %s") % section_label
		card.has_final = row.has_final
		card.final_open = row.final_open
		card.final_label = "Desafío final abierto" if row.final_open else "Abrir ya el desafío final"
		cards.append(card)
	return cards


## Habilita o deshabilita el paquete para la sección. Devuelve el aviso para el docente.
func set_enabled(card: PackageCardViewModel, section_id: String, section_label: String, enabled: bool) -> String:
	var saved := _set_access.execute(card.id, section_id, enabled, card.final_open and enabled)
	if not saved.is_ok():
		return saved.message
	if enabled:
		return "«%s» ya aparece en el mapa de %s." % [card.title, section_label]
	return "«%s» ya no aparece en el mapa de %s." % [card.title, section_label]


## Abre (o vuelve a cerrar) el desafío final antes de que terminen la práctica.
func set_final_open(card: PackageCardViewModel, section_id: String, section_label: String, open: bool) -> String:
	var saved := _set_access.execute(card.id, section_id, card.enabled, open)
	if not saved.is_ok():
		return saved.message
	if open:
		return "El desafío final de «%s» ya está abierto para %s." % [card.title, section_label]
	return "El desafío final de «%s» se abrirá al terminar la práctica." % card.title


func import_files() -> Array[ImportFileViewModel]:
	var files: Array[ImportFileViewModel] = []
	for found in _imports.execute():
		var file := ImportFileViewModel.new()
		file.path = found.path
		file.name = found.name
		file.detail = "%s MB" % PackageRules.megabytes(found.size_bytes) if found.size_bytes >= 102400 \
			else "%d KB" % ceili(found.size_bytes / 1024.0)
		files.append(file)
	return files


func import_hint() -> String:
	return "Copia el archivo .zip del paquete por USB o por cable en la carpeta %s de la tablet." % IMPORT_FOLDER


func install(path: String) -> InstallFeedbackViewModel:
	var feedback := InstallFeedbackViewModel.new()
	var installed := _install.execute(path)
	if not installed.is_ok():
		feedback.title = "No se instaló el paquete"
		feedback.message = installed.message
		return feedback
	var response: InstallResponse = installed.value
	feedback.ok = true
	match response.outcome:
		InstallResponse.UPDATED:
			feedback.title = "Paquete actualizado"
			feedback.message = "«%s» pasó de la versión %s a la %s. Los intentos guardados se conservan." % [
				response.title, response.previous_version, response.version]
		InstallResponse.UNCHANGED:
			feedback.title = "Ya estaba instalado"
			feedback.message = "La tablet ya tiene «%s» en su versión %s." % [response.title, response.version]
		_:
			feedback.title = "Paquete instalado"
			feedback.message = "«%s» (%d niveles) está listo. Habilítalo para cada sección que lo vaya a usar." % [
				response.title, response.level_count]
	return feedback
