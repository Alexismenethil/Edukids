class_name PackagesView
extends VBoxContainer
## Pestaña «Paquetes» del modo docente: los paquetes de la tablet con su habilitación por sección
## (RF-09) y la importación de un paquete copiado por USB o por cable (RF-19).

## Aviso breve para el docente (lo muestra el panel).
signal notice(text: String)

var _presenter: PackagesPresenter
var _sections: Array[SectionTabViewModel] = []
var _section_id := ""
var _section_label := ""
var _group := ButtonGroup.new()
var _list := Ui.vbox(12)
var _dialog: Control
var _dialog_list: VBoxContainer
var _dialog_result: Label


func setup(presenter: PackagesPresenter, sections: Array[SectionTabViewModel]) -> void:
	_presenter = presenter
	_sections = sections


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var title := Ui.label("Paquetes de la tablet", &"TitleLabel")
	title.add_theme_font_size_override("font_size", 38)
	var hint := Ui.label("Elige qué módulos y retos aparecen en el mapa de cada sección.", &"HintLabel")
	var heading := Ui.vbox(2, [title, hint])
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var import := Ui.compact(Ui.button("Importar paquete", "plus"), 24)
	import.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	import.pressed.connect(open_import)
	add_child(Ui.hbox(16, [heading, import]))
	var chips := Ui.hbox(10)
	for tab in _sections:
		var chip := Ui.chip(tab.label, _group)
		chip.toggled.connect(func(on: bool) -> void:
			if on:
				show_section(tab.id))
		chips.add_child(chip)
		if _section_id.is_empty():
			chip.set_pressed_no_signal(true)
			_section_id = tab.id
	add_child(chips)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	add_child(scroll)
	if not _section_id.is_empty():
		show_section(_section_id)


func show_section(section_id: String) -> void:
	_section_id = section_id
	for tab in _sections:
		if tab.id == section_id:
			_section_label = tab.label
	for child in _list.get_children():
		child.queue_free()
	var cards := _presenter.cards(_section_id, _section_label)
	for i in cards.size():
		var card := _make_card(cards[i])
		_list.add_child(card)
		Ui.pop_in(card, 0.03 * i)


func _make_card(card: PackageCardViewModel) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"RowPanel" if card.enabled else &"RowPanelInactive"
	var icon := PanelContainer.new()
	var disc := StyleBoxFlat.new()
	disc.bg_color = card.color if card.enabled else card.color.lerp(Color("#CFC6B8"), 0.6)
	disc.set_corner_radius_all(18)
	disc.set_content_margin_all(10)
	icon.add_theme_stylebox_override("panel", disc)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := TextureRect.new()
	glyph.texture = Ui.icon(card.icon)
	glyph.custom_minimum_size = Vector2(44, 44)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.add_child(glyph)
	var name_label := Ui.label(card.title, &"HeadingLabel")
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var detail := Ui.label(card.detail, &"HintLabel")
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var origin := PanelContainer.new()
	origin.theme_type_variation = &"BadgeMuted"
	origin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	origin.add_child(Ui.label(card.origin, &"BadgeLabel"))
	var texts := Ui.vbox(4, [name_label, detail, origin])
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var enabled := Ui.chip(card.enabled_label)
	enabled.custom_minimum_size.y = 52
	enabled.set_pressed_no_signal(card.enabled)
	var final := Ui.chip(card.final_label)
	final.custom_minimum_size.y = 52
	final.set_pressed_no_signal(card.final_open)
	final.disabled = not card.has_final or not card.enabled
	final.visible = card.has_final
	enabled.toggled.connect(func(on: bool) -> void:
		notice.emit(_presenter.set_enabled(card, _section_id, _section_label, on))
		show_section(_section_id))
	final.toggled.connect(func(on: bool) -> void:
		notice.emit(_presenter.set_final_open(card, _section_id, _section_label, on))
		show_section(_section_id))
	var toggles := Ui.vbox(8, [enabled, final])
	toggles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_child(Ui.hbox(18, [icon, texts, toggles]))
	return panel


## Abre la lista de paquetes copiados a la tablet para importar uno (lo usa el modo demostración).
func open_import() -> Control:
	if OS.get_name() == "Android":
		OS.request_permissions()
	if _dialog:
		_dialog.queue_free()
	_dialog = Control.new()
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.13, 0.1, 0.09, 0.55)
	_dialog.add_child(veil)
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size.x = 760
	var content := Ui.vbox(14)
	var title := Ui.label("Importar un paquete", &"TitleLabel")
	title.add_theme_font_size_override("font_size", 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Ui.compact(Ui.button("Cerrar", "", &"SoftButton"))
	close.pressed.connect(close_import)
	content.add_child(Ui.hbox(16, [title, close]))
	content.add_child(Ui.label(_presenter.import_hint(), &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 700))
	_dialog_list = Ui.vbox(10)
	content.add_child(_dialog_list)
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var browse := Ui.compact(Ui.button("Buscar en la tablet…", "packages", &"SoftButton"))
		browse.pressed.connect(_browse)
		content.add_child(browse)
	_dialog_result = Ui.label("", &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 700)
	_dialog_result.add_theme_font_size_override("font_size", 22)
	_dialog_result.visible = false
	content.add_child(_dialog_result)
	card.add_child(content)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_child(card)
	_dialog.add_child(center)
	get_tree().root.add_child(_dialog)
	_fill_import_list()
	Ui.pop_in(card)
	return _dialog


func _fill_import_list() -> void:
	for child in _dialog_list.get_children():
		child.queue_free()
	var files := _presenter.import_files()
	if files.is_empty():
		var empty := Ui.label("Todavía no hay archivos .zip en la tablet.", &"HeadingLabel")
		empty.add_theme_font_size_override("font_size", 22)
		_dialog_list.add_child(empty)
		return
	for file in files:
		var name_label := Ui.label(file.name, &"HeadingLabel")
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var texts := Ui.vbox(0, [name_label, Ui.label(file.detail, &"HintLabel")])
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var install := Ui.compact(Ui.button("Instalar", "check"))
		install.pressed.connect(install_file.bind(file.path))
		var row := PanelContainer.new()
		row.theme_type_variation = &"RowPanel"
		row.add_child(Ui.hbox(14, [texts, install]))
		_dialog_list.add_child(row)


## Instala el paquete del archivo indicado y muestra el resultado en la ventana de importar.
func install_file(path: String) -> void:
	var feedback := _presenter.install(path)
	if _dialog_result:
		_dialog_result.visible = true
		_dialog_result.text = "%s. %s" % [feedback.title, feedback.message]
		_dialog_result.add_theme_color_override("font_color", Color("#1F7A70") if feedback.ok else Color("#B23A48"))
	notice.emit(feedback.title)
	show_section(_section_id)


func _browse() -> void:
	DisplayServer.file_dialog_show("Elige el paquete (.zip)", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		PackedStringArray(["*.zip ; Paquetes de EduKids"]), func(status: bool, paths: PackedStringArray, _filter: int) -> void:
			if status and not paths.is_empty():
				install_file(paths[0]))


## Cierra la ventana de importar (si está abierta).
func close_import() -> void:
	if _dialog:
		_dialog.queue_free()
		_dialog = null


## Para el modo demostración: habilita un paquete (y su desafío final) en la sección que se ve.
func demo_set_access(package_id: String, enabled: bool, final_open: bool) -> void:
	for card in _presenter.cards(_section_id, _section_label):
		if card.id == package_id:
			notice.emit(_presenter.set_enabled(card, _section_id, _section_label, enabled))
			card.enabled = enabled
			if final_open:
				notice.emit(_presenter.set_final_open(card, _section_id, _section_label, true))
	show_section(_section_id)


func _exit_tree() -> void:
	close_import()
