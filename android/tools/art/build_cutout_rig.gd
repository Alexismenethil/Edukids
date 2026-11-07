extends SceneTree
## Construye el rig de un personaje por piezas (cut-out) a partir de su SVG maestro.
##
## 1. Rasteriza cada grupo part_* del SVG a la escala indicada (2× para tablets de alta densidad).
## 2. Recorta cada pieza y las empaca en un solo atlas PNG.
## 3. Genera la escena del rig: nodos con su pivote y Sprite2D con regiones del atlas.
##
## Uso (desde android/):
##   godot --headless --path . -s res://tools/art/build_cutout_rig.gd -- res://art-src/characters/quwi.rig.json
## Después: godot --headless --path . --import
##
## La escena generada no se edita a mano; la animación vive en el script del personaje.

## Ancho del atlas si el .rig.json no indica "atlas_width". El alto nunca debe pasar de 2048 px.
const ATLAS_WIDTH := 1024
const PADDING := 2
const GAP := 4


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Indica el archivo .rig.json del personaje.")
		quit(1)
		return
	quit(_build(args[0]))


func _build(rig_path: String) -> int:
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rig_path))
	var master_svg := FileAccess.get_file_as_string(rig["master"])
	var scale: float = rig["scale"]
	var nodes: Array = rig["nodes"]
	var atlas_width: int = int(rig.get("atlas_width", ATLAS_WIDTH))

	var part_names: Array[String] = []
	for node: Dictionary in nodes:
		if node.has("part"):
			part_names.append(node["part"])

	# 1. Rasterizar y recortar cada pieza.
	var pieces := {}
	for part in part_names:
		var image := Image.new()
		var error := image.load_svg_from_string(_isolate(master_svg, part, part_names), scale)
		if error != OK:
			printerr("No se pudo rasterizar la pieza ", part)
			return 1
		var used := image.get_used_rect()
		if used.size == Vector2i.ZERO:
			printerr("La pieza ", part, " está vacía.")
			return 1
		var bounds := used.grow(PADDING).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		pieces[part] = {"image": image.get_region(bounds), "origin": bounds.position}

	# 2. Empacar en estantes, de la pieza más alta a la más baja.
	var order := part_names.duplicate()
	order.sort_custom(func(a: String, b: String) -> bool:
		return pieces[a]["image"].get_height() > pieces[b]["image"].get_height())
	var cursor := Vector2i(GAP, GAP)
	var shelf_height := 0
	for part in order:
		var size: Vector2i = pieces[part]["image"].get_size()
		if cursor.x + size.x + GAP > atlas_width:
			cursor = Vector2i(GAP, cursor.y + shelf_height + GAP)
			shelf_height = 0
		pieces[part]["region"] = Rect2i(cursor, size)
		cursor.x += size.x + GAP
		shelf_height = maxi(shelf_height, size.y)
	var atlas_height := cursor.y + shelf_height + GAP
	atlas_height += (4 - atlas_height % 4) % 4
	var atlas := Image.create_empty(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)
	for part in order:
		var piece_image: Image = pieces[part]["image"]
		atlas.blit_rect(piece_image, Rect2i(Vector2i.ZERO, piece_image.get_size()), pieces[part]["region"].position)
	DirAccess.make_dir_recursive_absolute(String(rig["atlas"]).get_base_dir())
	atlas.save_png(rig["atlas"])

	# 3. Escribir la escena del rig.
	var scene_text := _scene_text(rig, pieces, scale)
	DirAccess.make_dir_recursive_absolute(String(rig["scene"]).get_base_dir())
	var file := FileAccess.open(rig["scene"], FileAccess.WRITE)
	file.store_string(scene_text)
	file.close()
	print("Rig listo: %d piezas en un atlas de %dx%d px -> %s" % [part_names.size(), atlas_width, atlas_height, rig["scene"]])
	return 0


## Deja visible solo la pieza pedida.
func _isolate(svg: String, part: String, all_parts: Array[String]) -> String:
	var result := svg
	for other in all_parts:
		if other != part:
			result = result.replace('<g id="part_%s">' % other, '<g id="part_%s" opacity="0">' % other)
	return result


func _scene_text(rig: Dictionary, pieces: Dictionary, scale: float) -> String:
	var lines: PackedStringArray = ["[gd_scene format=3]", ""]
	lines.append('[ext_resource type="Texture2D" path="%s" id="1_atlas"]' % rig["atlas"])
	lines.append("")
	for node: Dictionary in rig["nodes"]:
		if node.has("part"):
			var region: Rect2i = pieces[node["part"]]["region"]
			lines.append('[sub_resource type="AtlasTexture" id="AtlasTexture_%s"]' % node["part"])
			lines.append('atlas = ExtResource("1_atlas")')
			lines.append("region = Rect2(%d, %d, %d, %d)" % [region.position.x, region.position.y, region.size.x, region.size.y])
			lines.append("")
	lines.append('[node name="%s" type="Node2D"]' % rig["name"])
	lines.append("scale = Vector2(%s, %s)" % [_num(1.0 / scale), _num(1.0 / scale)])
	lines.append("")

	var pivots := {"": _vec(rig["origin"])}
	for node: Dictionary in rig["nodes"]:
		var parent: String = node["parent"]
		var pivot := _vec(node["pivot"])
		pivots[(parent + "/" if parent != "" else "") + String(node["name"])] = pivot
		var parent_pivot: Vector2 = pivots[parent]
		var position := (pivot - parent_pivot) * scale
		var type := "Sprite2D" if node.has("part") else "Node2D"
		lines.append('[node name="%s" type="%s" parent="%s"]' % [node["name"], type, parent if parent != "" else "."])
		if not node.get("visible", true):
			lines.append("visible = false")
		lines.append("position = Vector2(%s, %s)" % [_num(position.x), _num(position.y)])
		if node.has("part"):
			var origin: Vector2i = pieces[node["part"]]["origin"]
			var offset := Vector2(origin) - pivot * scale
			lines.append('texture = SubResource("AtlasTexture_%s")' % node["part"])
			lines.append("centered = false")
			lines.append("offset = Vector2(%s, %s)" % [_num(offset.x), _num(offset.y)])
		lines.append("")
	return "\n".join(lines)


func _vec(values: Array) -> Vector2:
	return Vector2(float(values[0]), float(values[1]))


func _num(value: float) -> String:
	return str(snappedf(value, 0.001))
