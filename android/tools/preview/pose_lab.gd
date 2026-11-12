extends Node2D
## Laboratorio de poses para revisar las animaciones de los personajes cuadro por cuadro.
## Uso (desde android/): godot --path . res://tools/preview/pose_lab.tscn -- <hoja> <ruta.png>
## Hojas: coco, avatar, atoq, condor. Guarda una captura y se cierra. No se exporta en el APK.

var _sheet := "coco"
var _actors: Array[Node2D] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#CFE8F4"))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var args := OS.get_cmdline_user_args()
	_sheet = args[0] if args.size() > 0 else "coco"
	var path := args[1] if args.size() > 1 else "user://pose_lab.png"
	call("_sheet_" + _sheet)
	for i in 8:
		await get_tree().process_frame
	call("_pose_" + _sheet)
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	print("Poses guardadas en ", path)
	get_tree().quit()


func _label(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_color_override("font_color", Color("#24502C"))
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)


func _sheet_coco() -> void:
	var settings := [["boca 0", 0.0], ["mastica 0.16", 0.16], ["media 0.5", 0.5], ["abierta 1", 1.0],
		["muerde 1.2", 1.2], ["en el aire", 1.0], ["fruta adentro", 0.9], ["enojado", 0.8]]
	for i in settings.size():
		var coco := CaimanCharacter.new()
		coco.position = Vector2(200 + (i % 4) * 300, 260 + (i / 4) * 330)
		coco.scale = Vector2.ONE * 0.62
		add_child(coco)
		_actors.append(coco)
		_label(settings[i][0], coco.position + Vector2(-110, 70))


func _pose_coco() -> void:
	var values := [0.0, 0.16, 0.5, 1.0, 1.2, 1.0, 0.9, 0.8]
	for i in _actors.size():
		var coco: CaimanCharacter = _actors[i]
		coco.set_process(false)
		coco.mouth = values[i]
		if i == 5:
			coco.airborne = 1.0
			coco.rotation = 0.3
		if i == 6:
			var fruit := FruitSprite.new()
			fruit.kind = &"tuna"
			fruit.size_factor = 3.4
			coco.add_child(fruit)
			coco.hold(fruit)
		if i == 7:
			coco.set_mood(&"angry")
		coco._process(0.016)
		coco.set_process(false)
