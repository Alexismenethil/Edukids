extends SceneTree
## Arma el primer borrador del rig de un personaje a partir de su SVG por piezas: mide cada grupo
## part_* y propone los nodos, sus padres y sus pivotes. También deja el esqueleto del script del
## personaje. Después solo queda afinar los pivotes a mano y generar el atlas.
##
## Uso (desde android/):
##   godot --headless --path . -s res://tools/art/scaffold_rig.gd -- res://art-src/characters/llama.svg
## Con --force reemplaza un .rig.json o un script que ya existan.
##
## Convenciones que entiende:
##   part_eyes_*   variantes de ojos (hijas de «Eyes»)      part_mouth_*  variantes de boca («Mouth»)
##   part_head     la cabeza: ojos, boca, cejas, rubor, orejas, pelo y sombrero cuelgan de «Head»
##   part_arm_*, part_leg_*, part_wing_*, part_tail, part_ear_*, part_braid_*: piezas que giran;
##   su pivote se propone en el extremo más cercano al centro del cuerpo.

const HEAD_PARTS: Array[String] = ["head", "brow", "blush", "cheek", "ear", "hat", "hair", "braid", "nose", "beak"]
const LIMBS: Array[String] = ["arm", "leg", "wing", "tail", "ear", "braid", "foot", "hand", "scarf_tail"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Indica el SVG del personaje (res://art-src/characters/<nombre>.svg).")
		quit(1)
		return
	quit(_scaffold(args[0], args.has("--force")))


func _scaffold(svg_path: String, force: bool) -> int:
	var svg := FileAccess.get_file_as_string(svg_path)
	if svg.is_empty():
		printerr("No se pudo leer ", svg_path)
		return 1
	var character := svg_path.get_file().get_basename()
	var matcher := RegEx.new()
	matcher.compile("<g id=\"part_([a-z0-9_]+)\">")
	var parts: Array[String] = []
	for found in matcher.search_all(svg):
		parts.append(found.get_string(1))
	if parts.is_empty():
		printerr("El SVG no tiene grupos <g id=\"part_...\"> de primer nivel.")
		return 1

	# Medir cada pieza.
	var boxes := {}
	var whole := Rect2()
	for part in parts:
		var isolated := svg
		for other in parts:
			if other != part:
				isolated = isolated.replace('<g id="part_%s">' % other, '<g id="part_%s" opacity="0">' % other)
		var image := Image.new()
		if image.load_svg_from_string(isolated, 1.0) != OK:
			printerr("No se pudo rasterizar la pieza ", part)
			return 1
		var used := Rect2(image.get_used_rect())
		boxes[part] = used
		whole = used if whole.size == Vector2.ZERO else whole.merge(used)
	var center := whole.get_center()
	var has_head := parts.has("head")
	var head_box: Rect2 = boxes.get("head", Rect2())

	# Proponer los nodos, en el orden del dibujo.
	var nodes: Array = []
	var bones: Array = []
	var group_done := {}
	var head_added := false
	for part in parts:
		var box: Rect2 = boxes[part]
		var group := ""
		if part.begins_with("eyes_"):
			group = "Eyes"
		elif part.begins_with("mouth_"):
			group = "Mouth"
		var on_head := has_head and (group != "" or _matches(part, HEAD_PARTS))
		if on_head and not head_added:
			head_added = true
			nodes.append({"name": "Head", "parent": "", "pivot": _pair(Vector2(head_box.get_center().x, head_box.end.y))})
			bones.append(["head", "Head"])
		var parent := "Head" if on_head else ""
		if group != "":
			if not group_done.has(group):
				var union := Rect2()
				for other in parts:
					if other.begins_with(group.to_lower() + "_"):
						union = boxes[other] if union.size == Vector2.ZERO else union.merge(boxes[other])
				group_done[group] = union.get_center()
				nodes.append({"name": group, "parent": parent, "pivot": _pair(union.get_center())})
			var variant := {"name": part.to_pascal_case(), "parent": (parent + "/" if parent != "" else "") + group, "part": part,
				"pivot": _pair(group_done[group])}
			if nodes.any(func(node: Dictionary) -> bool: return node.get("parent", "") == variant["parent"]):
				variant["visible"] = false
			nodes.append(variant)
			continue
		var node_name := "HeadArt" if part == "head" else part.to_pascal_case()
		var pivot := box.get_center()
		if part == "head":
			pivot = Vector2(head_box.get_center().x, head_box.end.y)
		elif _matches(part, LIMBS):
			pivot = _joint(box, center)
		nodes.append({"name": node_name, "parent": parent, "part": part, "pivot": _pair(pivot)})
		if part != "head":
			bones.append([part, (parent + "/" if parent != "" else "") + node_name])

	var rig := {
		"name": character.to_pascal_case() + "Rig",
		"master": svg_path,
		"scale": 2.0,
		"origin": _pair(Vector2(center.x, whole.end.y)),
		"atlas": "res://assets/art/characters/%s/char_%s_atlas.png" % [character, character],
		"scene": "res://scenes/characters/%s/%s_rig.tscn" % [character, character],
	}
	var text := "{\n"
	for key: String in rig:
		text += "  %s: %s,\n" % [JSON.stringify(key), JSON.stringify(rig[key])]
	var lines: PackedStringArray = []
	for node: Dictionary in nodes:
		lines.append("    " + JSON.stringify(node, "", false))
	text += "  \"nodes\": [\n" + ",\n".join(lines) + "\n  ]\n}\n"
	var rig_path := svg_path.get_basename() + ".rig.json"
	if not _write(rig_path, text, force):
		return 1

	var script_path := "res://scenes/characters/%s/%s.gd" % [character, character]
	DirAccess.make_dir_recursive_absolute(script_path.get_base_dir())
	_write(script_path, _script_text(character, bones, head_added, group_done.has("Eyes"), whole), force)

	print("Borrador del rig: %d piezas -> %s" % [parts.size(), rig_path])
	print("Qué sigue:")
	print("  1. Revisa los pivotes en ", rig_path, " (están en las coordenadas del SVG).")
	print("  2. godot --headless --path . -s res://tools/art/build_cutout_rig.gd -- ", rig_path)
	print("  3. godot --headless --path . --import")
	print("  4. Agrega «%s» a scenes/characters/cast.gd y pruébalo con: godot --path . -- --lab" % character)
	return 0


func _matches(part: String, words: Array[String]) -> bool:
	for word in words:
		if part == word or part.begins_with(word + "_") or part.ends_with("_" + word) or part.contains("_" + word + "_"):
			return true
	return false


## Articulación de una pieza que gira: el extremo de su caja más cercano al centro del cuerpo.
func _joint(box: Rect2, center: Vector2) -> Vector2:
	if box.size.y >= box.size.x:
		var top := Vector2(box.get_center().x, box.position.y + box.size.y * 0.08)
		var bottom := Vector2(box.get_center().x, box.end.y - box.size.y * 0.08)
		return top if absf(top.y - center.y) < absf(bottom.y - center.y) else bottom
	var left := Vector2(box.position.x + box.size.x * 0.08, box.get_center().y)
	var right := Vector2(box.end.x - box.size.x * 0.08, box.get_center().y)
	return left if absf(left.x - center.x) < absf(right.x - center.x) else right


func _pair(point: Vector2) -> Array:
	return [snappedf(point.x, 1.0), snappedf(point.y, 1.0)]


func _write(path: String, text: String, force: bool) -> bool:
	if FileAccess.file_exists(path) and not force:
		print("Ya existe ", path, " (usa --force para reemplazarlo).")
		return path.ends_with(".gd")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("No se pudo escribir ", path)
		return false
	file.store_string(text)
	file.close()
	return true


func _script_text(character: String, bones: Array, has_head: bool, has_face: bool, whole: Rect2) -> String:
	var class_title := character.to_pascal_case()
	var map: PackedStringArray = []
	for bone: Array in bones:
		map.append("\t\t&\"%s\": \"%s\"," % [bone[0], bone[1]])
	var height := snappedf(whole.size.y, 1.0)
	var text := "class_name %sCharacter\nextends Puppet\n" % class_title
	text += "## %s. Describe aquí quién es y qué sabe hacer. Solo anima: las reglas viven en el dominio.\n\n" % class_title
	text += "const RIG := preload(\"res://scenes/characters/%s/%s_rig.tscn\")\n\n" % [character, character]
	text += "const EXPRESSIONS := {\n\t&\"neutral\": {\"eyes\": &\"open\", \"mouth\": &\"smile\"},\n"
	text += "\t&\"happy\": {\"eyes\": &\"happy\", \"mouth\": &\"smile\", \"brows\": 4.0},\n"
	text += "\t&\"wow\": {\"eyes\": &\"open\", \"mouth\": &\"o\", \"brows\": 12.0, \"eyes_scale\": 1.15},\n}\n\n"
	text += "const CLIPS := {\n\t# Un gesto propio: cambia el hueso y las claves.\n"
	text += "\t&\"greet\": {\"group\": &\"body\", \"tracks\": {\n\t\t\"lean\": [[0.2, 0.08, \"back\"], [0.7, 0.08], [1.0, 0.0]],\n"
	text += "\t\t\"face\": [[0.0, \"happy\"], [1.0, \"\"]],\n\t}},\n}\n\n\n"
	text += "func _setup() -> void:\n\t_use_rig(RIG)\n\t_bone_map({\n%s\n\t})\n" % "\n".join(map)
	text += "\tshadow_radius = %s\n" % snappedf(whole.size.x * 0.3, 1.0)
	text += "\thit_rect = Rect2(%s, %s, %s, %s)\n" % [-snappedf(whole.size.x * 0.5, 1.0), -height, snappedf(whole.size.x, 1.0), height + 10.0]
	text += "\tbody_center = Vector2(0.0, %s)\n" % (-snappedf(height * 0.5, 1.0))
	text += "\temote_anchor = Vector2(%s, %s)\n\n" % [snappedf(whole.size.x * 0.3, 1.0), -height + 20.0]
	text += "\t# Reposo vivo: respiración y vaivenes.\n\t# _breathe(&\"body\")\n"
	if has_head:
		text += "\t_sway(&\"head\", \"rot\", 0.03, 1.2)\n"
	text += "\t# Piezas con rebote: _spring(&\"tail\", Vector2.LEFT, 120.0, {\"limit\": 0.6})\n\n"
	if has_face and has_head:
		text += "\t_face_setup(^\"Head\", EXPRESSIONS, {\"talk\": [&\"open\", &\"smile\"]})\n\t_look_layer(&\"eyes\", Vector2(1.0, 1.0))\n"
	text += "\t_clip_set(CLIPS)\n\tfidgets = [&\"look_around\", &\"stretch\"]\n\ttap_reactions = [&\"greet\", &\"laugh\", &\"flip\"]\n"
	return text
