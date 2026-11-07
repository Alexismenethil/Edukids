extends Node2D
## Dibuja la colita del globo por encima del panel.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	(get_parent() as SpeechBubble).draw_tail(self)
