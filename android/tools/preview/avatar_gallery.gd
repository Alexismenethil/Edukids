extends Node2D
## Galería de avatares para revisar el arte: todas las combinaciones de peinado, piel y ropa.
## Uso (desde android/): godot --path . res://tools/preview/avatar_gallery.tscn -- <ruta.png>
## Guarda una captura y se cierra. No se exporta en el APK.

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#CFE8F4"))
	var looks: Array[Dictionary] = []
	for style in 6:
		looks.append({"body": "girl" if style in [3, 4, 5] else "boy", "skin": style, "hair_style": style,
			"hair_color": style % 5, "top_color": style, "bottom_color": (style + 3) % 8})
	for style in 6:
		looks.append({"body": "boy" if style in [3, 4, 5] else "girl", "skin": 5 - style, "hair_style": style,
			"hair_color": (style + 2) % 5, "top_color": 7 - style, "bottom_color": (style + 5) % 8})
	for i in looks.size():
		var avatar: AvatarCharacter = AVATAR.instantiate()
		avatar.lively = false
		avatar.position = Vector2(110 + (i % 6) * 212, 380 + (i / 6) * 400)
		avatar.scale = Vector2.ONE * 0.92
		add_child(avatar)
		avatar.apply(AvatarPalette.look_for(looks[i]))
	var silhouette: AvatarCharacter = AVATAR.instantiate()
	silhouette.lively = false
	silhouette.position = Vector2(1180, 380)
	silhouette.scale = Vector2.ONE * 0.5
	add_child(silhouette)
	silhouette.apply(AvatarPalette.look_for({}))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var path := args[0] if not args.is_empty() else "user://avatar_gallery.png"
	get_viewport().get_texture().get_image().save_png(path)
	print("Galería guardada en ", path)
	get_tree().quit()
