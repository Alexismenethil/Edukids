class_name SequentialIds
extends IdGenerator
## Identificadores predecibles para las pruebas: id-1, id-2, id-3...

var _count := 0


func next_id() -> String:
	_count += 1
	return "id-%d" % _count
