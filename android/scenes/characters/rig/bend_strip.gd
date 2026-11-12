class_name BendStrip
extends Node2D
## Una pieza del rig que se dobla suave (colas, trenzas, cola de caballo): la textura se reparte en
## segmentos a lo largo de su eje y cada articulación gira un poco respecto de la anterior, como en
## la animación 2D por mallas. Así la pieza se curva sin cortes ni costuras.
##
## Se crea a partir del Sprite2D que genera el rig (`from_sprite`) y se dobla con `bends` o `wave`.

## Pieza a deformar (puede ser una región de un atlas).
var texture: Texture2D
## Esquina de la textura respecto del pivote (el `offset` del Sprite2D original).
var offset := Vector2.ZERO
## Eje de la pieza en el espacio local: de la raíz (donde se une) a la punta.
var root := Vector2.ZERO
var tip := Vector2(100, 0)
## Número de segmentos: más segmentos, curva más suave.
var segments := 10:
	set(value):
		segments = maxi(1, value)
		bends.resize(segments)
## Giro de cada articulación en radianes, de la raíz a la punta. Se suma de una a la siguiente.
var bends := PackedFloat32Array()

var _atlas: Texture2D
var _region := Rect2()


func _init() -> void:
	bends.resize(segments)


## Reemplaza el sprite del rig por una tira flexible en el mismo lugar del árbol. `root_local` y
## `tip_local` van en el espacio local del sprite (el de su pivote).
static func from_sprite(sprite: Sprite2D, root_local: Vector2, tip_local: Vector2, pieces: int = 10) -> BendStrip:
	var strip := BendStrip.new()
	strip.name = sprite.name
	strip.texture = sprite.texture
	strip.offset = sprite.offset
	strip.root = root_local
	strip.tip = tip_local
	strip.segments = pieces
	strip.transform = sprite.transform
	strip.visible = sprite.visible
	strip.self_modulate = sprite.self_modulate
	var parent := sprite.get_parent()
	var index := sprite.get_index()
	parent.remove_child(sprite)
	sprite.queue_free()
	parent.add_child(strip)
	parent.move_child(strip, index)
	for child in sprite.get_children():
		child.reparent(strip, false)
	return strip


## Curva toda la pieza: `curl` reparte un giro parejo y `amplitude` agrega una onda que viaja de la
## raíz a la punta (con `phase`), más fuerte hacia la punta. Ideal para colas y pelo.
func wave(curl: float, amplitude: float, phase: float, wavelength: float = 1.0) -> void:
	for i in segments:
		var t := float(i) / float(segments)
		var reach := pow(t + 1.0 / segments, 1.4)
		bends[i] = curl / segments + amplitude * reach * sin(phase - t * TAU * 0.5 * wavelength) / segments * 2.2
	queue_redraw()


func _ready() -> void:
	_resolve()


func _resolve() -> void:
	if texture is AtlasTexture:
		_atlas = (texture as AtlasTexture).atlas
		_region = (texture as AtlasTexture).region
	elif texture:
		_atlas = texture
		_region = Rect2(Vector2.ZERO, texture.get_size())


func _draw() -> void:
	if texture == null:
		return
	if _atlas == null:
		_resolve()
	var axis := tip - root
	var length := axis.length()
	if length < 1.0:
		return
	var u := axis / length
	var n := Vector2(-u.y, u.x)
	var rect := Rect2(offset, _region.size)
	# Extensión del dibujo sobre el eje, medida desde la raíz. Cada esquina es una muestra: así la
	# malla calza justo con la pieza aunque el eje vaya en diagonal.
	var samples: Array[float] = []
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		samples.append((corner - root).dot(u))
	var step := length / segments
	for i in segments + 1:
		samples.append(step * i)
	samples.sort()
	# Dirección de cada segmento (suma de los giros desde la raíz) y posición de cada articulación.
	var headings := PackedFloat32Array()
	var joints := PackedVector2Array([root])
	var heading := 0.0
	for i in segments:
		heading += bends[i]
		headings.append(heading)
		joints.append(joints[i] + u.rotated(heading) * step)
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var atlas_size := _atlas.get_size()
	var last := -INF
	for a in samples:
		if a - last < 0.01:
			continue
		last = a
		# Punto del eje curvado y su dirección; fuera de la raíz y de la punta sigue recto.
		var spine: Vector2
		var turn: float
		if a <= 0.0:
			spine = root + u * a
			turn = 0.0
		elif a >= length:
			turn = headings[segments - 1]
			spine = joints[segments] + u.rotated(turn) * (a - length)
		else:
			var index := mini(int(a / step), segments - 1)
			var along := a - index * step
			spine = joints[index] + u.rotated(headings[index]) * along
			var before := headings[index - 1] if index > 0 else 0.0
			var after := headings[index + 1] if index < segments - 1 else headings[index]
			var here := headings[index]
			var t := along / step
			turn = lerpf((before + here) * 0.5, here, t * 2.0) if t < 0.5 else lerpf(here, (here + after) * 0.5, t * 2.0 - 1.0)
		var normal := n.rotated(turn)
		# Tramo de la pieza que cruza el eje en este punto (recorte de la recta contra el rectángulo).
		var origin := root + u * a
		var low := -INF
		var high := INF
		for k in 2:
			var direction := n[k]
			var from := rect.position[k] - origin[k]
			var to := rect.end[k] - origin[k]
			if absf(direction) < 0.00001:
				continue
			var b0 := from / direction
			var b1 := to / direction
			low = maxf(low, minf(b0, b1))
			high = minf(high, maxf(b0, b1))
		if is_inf(low) or is_inf(high) or low > high:
			var middle := 0.0 if is_inf(low) or is_inf(high) else (low + high) * 0.5
			low = middle
			high = middle
		for b: float in [low, high]:
			points.append(spine + normal * b)
			var source := (origin + n * b - offset).clamp(Vector2.ZERO, _region.size)
			uvs.append((_region.position + source) / atlas_size)
			colors.append(Color.WHITE)
	var indices := PackedInt32Array()
	for i in points.size() / 2 - 1:
		var k := i * 2
		indices.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])
	if indices.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors, uvs,
		PackedInt32Array(), PackedFloat32Array(), _atlas.get_rid())
