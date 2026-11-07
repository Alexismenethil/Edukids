class_name ConfirmDialog
extends Control
## Pregunta de confirmación sobre un velo: un texto, una explicación y dos botones.

signal confirmed
signal cancelled


func _init(question: String = "", detail: String = "", confirm_label: String = "", cancel_label: String = "") -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := Panel.new()
	veil.theme_type_variation = &"VeilPanel"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := Ui.vbox(18)
	box.add_child(Ui.label(question, &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 520))
	box.add_child(Ui.label(detail, &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 520))
	var stay := Ui.button(cancel_label, "play")
	var leave := Ui.button(confirm_label, "exit", &"SoftButton")
	stay.pressed.connect(func() -> void:
		cancelled.emit()
		queue_free())
	leave.pressed.connect(func() -> void:
		confirmed.emit()
		queue_free())
	var buttons := Ui.hbox(18, [leave, stay])
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	card.add_child(box)
	add_child(card)


func _ready() -> void:
	Ui.pop_in(get_child(1), 0.0)
