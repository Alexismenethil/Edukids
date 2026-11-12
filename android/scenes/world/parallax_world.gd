class_name ParallaxWorld
extends Node2D
## Mundo de una escena de juego, armado por capas con paralaje. La cámara avanza con `cam_x` y
## encuadra: el punto `focus` del mundo se ve en `screen_focus`, con `zoom`. Cada capa se mueve
## según su profundidad: 0 es el cielo (no se mueve), 1 es el plano de los personajes y más de 1
## es el primer plano, que pasa más rápido.
##
## Las capas repetibles se dibujan con varias copias seguidas, así el mundo corre sin fin.

const SKY_SHADER := preload("res://scenes/world/sky.gdshader")
const RAYS_SHADER := preload("res://scenes/world/rays.gdshader")
const FOG_SHADER := preload("res://scenes/world/fog.gdshader")
const SWAY_SHADER := preload("res://scenes/world/sway.gdshader")
const WATER_SHADER := preload("res://scenes/world/water.gdshader")

## Tamaño de la pantalla donde se ve el mundo.
var view_size := Vector2(1280, 800)
## Cuánto avanzó la cámara en el plano de los personajes.
var cam_x := 0.0
var zoom := 1.0
var focus := Vector2(640, 400)
var screen_focus := Vector2(640, 400)
## Sacudida de la cámara (en la pantalla).
var shake_offset := Vector2.ZERO
## Golpe de zoom: multiplica el zoom un instante (impactos, aciertos).
var kick := 1.0

var _layers: Array[Dictionary] = []
var _planes: Array[Dictionary] = []
var _bands: Array[Dictionary] = []
var _clouds: Array[Dictionary] = []
var _time := 0.0
static var _fog_noise: NoiseTexture2D


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Lo que se ve del mundo, en sus coordenadas.
func visible_rect() -> Rect2:
	var scale_now := zoom * kick
	var origin := -(screen_focus + shake_offset - focus * scale_now) / scale_now
	return Rect2(origin, view_size / scale_now)


## Pasa un punto del mundo (plano de los personajes) a la pantalla.
func to_screen(point: Vector2) -> Vector2:
	return (point - focus) * zoom * kick + screen_focus + shake_offset


# --- Armado -----------------------------------------------------------------------------------

## Cielo con degradado vertical (en el mundo) y el sol con su halo.
func add_sky(colors: PackedColorArray, offsets: PackedFloat32Array, y_top: float, y_bottom: float,
		sun: Vector2, sun_radius: float = 46.0) -> ColorRect:
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 256
	var material := ShaderMaterial.new()
	material.shader = SKY_SHADER
	material.set_shader_parameter("gradient", texture)
	material.set_shader_parameter("y_top", y_top)
	material.set_shader_parameter("y_bottom", y_bottom)
	material.set_shader_parameter("sun", sun)
	material.set_shader_parameter("sun_radius", sun_radius)
	return _add_band(material, -INF, INF, 0.0)


## Nubes que se mueven solas y apenas con la cámara.
func add_clouds(textures: Array[Texture2D], specs: Array, px_per_unit: float = 1.5) -> void:
	for spec: Dictionary in specs:
		var sprite := Sprite2D.new()
		sprite.texture = textures[int(spec.get("texture", 0)) % textures.size()]
		sprite.scale = Vector2.ONE * float(spec.get("scale", 1.0)) / px_per_unit
		sprite.modulate.a = float(spec.get("alpha", 1.0))
		add_child(sprite)
		_clouds.append({"node": sprite, "x": float(spec["x"]), "y": float(spec["y"]),
			"speed": float(spec.get("speed", 8.0)), "depth": float(spec.get("depth", 0.04))})


## Una capa pintada. Si `repeat`, se repite a lo ancho sin fin.
func add_layer(texture: Texture2D, depth: float, top: float, px_per_unit: float, repeat := true,
		x := 0.0) -> Node2D:
	var holder := Node2D.new()
	add_child(holder)
	var tiles: Array[Sprite2D] = []
	for i in (3 if repeat else 1):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.scale = Vector2.ONE / px_per_unit
		holder.add_child(sprite)
		tiles.append(sprite)
	_layers.append({"holder": holder, "tiles": tiles, "depth": depth, "top": top,
		"width": texture.get_width() / px_per_unit, "repeat": repeat, "x": x})
	return holder


## El pasto de la capa se mece con el viento (las puntas, no la base).
func sway(layer: Node2D, amplitude: float = 4.0, speed: float = 1.5) -> void:
	var material := ShaderMaterial.new()
	material.shader = SWAY_SHADER
	material.set_shader_parameter("amplitude", amplitude)
	material.set_shader_parameter("speed", speed)
	for tile in layer.get_children():
		(tile as CanvasItem).material = material


## Rayos de sol (suman luz). Solo cubren el cielo y los cerros, hasta `bottom`.
func add_rays(sun: Vector2, intensity: float = 0.16, bottom: float = 760.0) -> ColorRect:
	var material := ShaderMaterial.new()
	material.shader = RAYS_SHADER
	material.set_shader_parameter("sun", sun)
	material.set_shader_parameter("intensity", intensity)
	return _add_band(material, -INF, bottom, 0.0)


## Banda de neblina entre dos alturas del mundo.
func add_fog(y_top: float, y_bottom: float, depth: float, color: Color) -> ColorRect:
	var material := ShaderMaterial.new()
	material.shader = FOG_SHADER
	material.set_shader_parameter("noise", _noise())
	material.set_shader_parameter("color", color)
	return _add_band(material, y_top, y_bottom, depth)


## Agua (río o laguna) entre dos alturas del mundo, con líneas de corriente.
func add_water(y_top: float, y_bottom: float, depth: float, flow: float = 60.0, shallow := Color("#6BCBE6"),
		deep := Color("#2A86B8")) -> ColorRect:
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("flow", flow)
	material.set_shader_parameter("shallow", shallow)
	material.set_shader_parameter("deep", deep)
	return _add_band(material, y_top, y_bottom, depth)


## Un relleno liso entre dos alturas (lo que hay debajo del primer plano, por ejemplo).
func add_fill(y_top: float, y_bottom: float, color: Color) -> ColorRect:
	var band := _add_band(null, y_top, y_bottom, 0.0)
	band.color = color
	return band


## Un plano para objetos sueltos que se mueven con la cámara según su profundidad.
func add_plane(depth: float) -> Node2D:
	var plane := Node2D.new()
	add_child(plane)
	_planes.append({"node": plane, "depth": depth})
	return plane


## Un contenedor quieto respecto de la cámara (los personajes que corren en su lugar).
func add_stage() -> Node2D:
	var stage := Node2D.new()
	add_child(stage)
	return stage


func _add_band(material: ShaderMaterial, y_top: float, y_bottom: float, depth: float) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = material
	add_child(rect)
	_bands.append({"node": rect, "top": y_top, "bottom": y_bottom, "depth": depth})
	return rect


func _noise() -> NoiseTexture2D:
	if _fog_noise:
		return _fog_noise
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	_fog_noise = NoiseTexture2D.new()
	_fog_noise.noise = noise
	_fog_noise.width = 256
	_fog_noise.height = 64
	_fog_noise.seamless = true
	return _fog_noise


# --- Cada cuadro ------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	refresh()


func refresh() -> void:
	position = screen_focus + shake_offset - focus * zoom * kick
	scale = Vector2(zoom, zoom) * kick
	var view := visible_rect().grow(6.0)
	for layer in _layers:
		var shift := cam_x * float(layer["depth"])
		var tiles: Array[Sprite2D] = layer["tiles"]
		if layer["repeat"]:
			var width: float = layer["width"]
			var start := floorf((view.position.x + shift) / width) * width - shift
			for i in tiles.size():
				tiles[i].position = Vector2(start + i * width, layer["top"])
				tiles[i].visible = tiles[i].position.x < view.end.x
		else:
			tiles[0].position = Vector2(float(layer["x"]) - shift, layer["top"])
	for band in _bands:
		var node: ColorRect = band["node"]
		var top: float = band["top"]
		var bottom: float = band["bottom"]
		var y0 := view.position.y if is_inf(top) else top
		var y1 := view.end.y if is_inf(bottom) else bottom
		node.position = Vector2(view.position.x, y0)
		node.size = Vector2(view.size.x, maxf(1.0, y1 - y0))
		if node.material:
			var material := node.material as ShaderMaterial
			material.set_shader_parameter("rect", Vector4(node.position.x, node.position.y, node.size.x, node.size.y))
			material.set_shader_parameter("scroll", cam_x * float(band["depth"]))
	var span := maxf(3200.0, view.size.x + 900.0)
	for cloud in _clouds:
		var sprite: Sprite2D = cloud["node"]
		var x := float(cloud["x"]) + _time * float(cloud["speed"]) - cam_x * float(cloud["depth"])
		sprite.position = Vector2(view.position.x - 450.0 + fposmod(x, span), cloud["y"])
	for plane in _planes:
		(plane["node"] as Node2D).position.x = -cam_x * float(plane["depth"])
