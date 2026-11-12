class_name FruitSprite
extends Node2D
## Frutas de la feria de Huamanga para Coco: tuna, palta, choclo, lúcuma y papa.

var kind: StringName = &"tuna"
var size_factor := 1.0


func _draw() -> void:
	paint(self, Vector2.ZERO, kind, size_factor)


static func paint(canvas: CanvasItem, at: Vector2, fruit: StringName, factor: float = 1.0) -> void:
	var s := factor
	var line := Color("#5A2E16")
	match fruit:
		&"palta":
			canvas.draw_circle(at + Vector2(0, 4) * s, 10.0 * s, Color("#4E7D2A"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(0, -5) * s, 7.0 * s, Color("#4E7D2A"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(-2, 2) * s, 5.0 * s, Color("#7FAE45"), true, -1.0, true)
			canvas.draw_line(at + Vector2(0, -12) * s, at + Vector2(2, -16) * s, line, 2.0 * s)
		&"choclo":
			canvas.draw_set_transform(at, 0.3, Vector2.ONE)
			canvas.draw_rect(Rect2(Vector2(-6, -14) * s, Vector2(12, 26) * s), Color("#F2C14E"))
			for row in 5:
				for column in 2:
					canvas.draw_circle(Vector2(-3 + column * 6, -11 + row * 5) * s, 2.2 * s, Color("#FFF3B0"), true, -1.0, true)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8, 12) * s, Vector2(-12, -6) * s, Vector2(-2, 8) * s]), Color("#7FAE45"))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(8, 12) * s, Vector2(12, -8) * s, Vector2(2, 8) * s]), Color("#6E9A38"))
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		&"lucuma":
			canvas.draw_circle(at, 10.0 * s, Color("#8A6A2E"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(-2, -2) * s, 7.0 * s, Color("#B08A3E"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(3, 3) * s, 3.0 * s, Color("#F2A93B"), true, -1.0, true)
		&"papa":
			canvas.draw_circle(at + Vector2(-4, 0) * s, 8.0 * s, Color("#C79A5B"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(5, 1) * s, 7.0 * s, Color("#C79A5B"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(-3, -2) * s, 1.5 * s, Color("#8A6A3A"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(5, 2) * s, 1.5 * s, Color("#8A6A3A"), true, -1.0, true)
		_:
			canvas.draw_circle(at, 10.5 * s, Color("#B4234E"), true, -1.0, true)
			canvas.draw_circle(at + Vector2(-3, -3) * s, 5.0 * s, Color("#D9466E"), true, -1.0, true)
			for dot in [Vector2(-5, 3), Vector2(4, -4), Vector2(5, 5), Vector2(-1, 7)]:
				canvas.draw_circle(at + dot * s, 1.3 * s, Color("#F7C8D4"), true, -1.0, true)
			canvas.draw_rect(Rect2(at + Vector2(-3, -13) * s, Vector2(6, 4) * s), Color("#6E9A38"))
