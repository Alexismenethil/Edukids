class_name EvaluatorRegistry
extends RefCounted
## Elige el evaluador según el campo `type` del ítem y arma los ítems a partir del contenido
## de un paquete, validando los campos comunes (formato de paquete v1).

var _evaluators := {}


## Registro con los evaluadores de los tipos de ítem P1.
static func standard() -> EvaluatorRegistry:
	var registry := EvaluatorRegistry.new()
	for evaluator: ItemEvaluator in [
		MultipleChoiceEvaluator.new(),
		MultiSelectEvaluator.new(),
		TrueFalseEvaluator.new(),
		OrderingEvaluator.new(),
		MatchingEvaluator.new(),
		ClassificationEvaluator.new(),
		FillBlankEvaluator.new(),
		NumericEvaluator.new(),
		ReadingUnitEvaluator.new(registry),
	]:
		registry.add(evaluator)
	return registry


func add(evaluator: ItemEvaluator) -> void:
	_evaluators[evaluator.type()] = evaluator


func supports(item_type: StringName) -> bool:
	return _evaluators.has(item_type)


func types() -> Array[StringName]:
	var found: Array[StringName] = []
	for key: StringName in _evaluators.keys():
		found.append(key)
	return found


## Valida un ítem del archivo de nivel y lo devuelve como Item.
## Dentro de una unidad de lectura no se permite otra unidad (`allow_units` en false).
func parse_item(raw: Variant, allow_units: bool = true) -> Result:
	if typeof(raw) != TYPE_DICTIONARY:
		return Result.fail(&"item_invalid", "Cada ítem debe ser un objeto.")
	var item := Item.new()
	item.id = str(raw.get("id", "")).strip_edges()
	if item.id.is_empty():
		return Result.fail(&"item_invalid", "Hay un ítem sin «id».")
	item.type = StringName(str(raw.get("type", "")))
	if not supports(item.type) or (item.type == ItemType.READING_UNIT and not allow_units):
		return ItemEvaluator.invalid(item.id, "el tipo «%s» no se puede usar aquí" % item.type)
	item.prompt = str(raw.get("prompt", "")).strip_edges()
	if item.prompt.is_empty():
		return ItemEvaluator.invalid(item.id, "falta el enunciado («prompt»)")
	item.image = str(raw.get("image", "")).strip_edges()
	item.hint = str(raw.get("hint", "")).strip_edges()
	var feedback: Variant = raw.get("feedback", {})
	if typeof(feedback) == TYPE_DICTIONARY:
		item.feedback_correct = str(feedback.get("correct", "")).strip_edges()
		item.feedback_incorrect = str(feedback.get("incorrect", "")).strip_edges()
	if item.type != ItemType.READING_UNIT and (item.feedback_correct.is_empty() or item.feedback_incorrect.is_empty()):
		return ItemEvaluator.invalid(item.id, "falta la retroalimentación «correct» o «incorrect»")
	var metadata: Variant = raw.get("metadata", {})
	item.metadata = metadata if typeof(metadata) == TYPE_DICTIONARY else {}
	var spec: Result = _evaluators[item.type].parse_spec(raw, item.id)
	if not spec.is_ok():
		return spec
	item.spec = spec.value
	return Result.ok(item)


func evaluate(item: Item, answer: Variant) -> Evaluation:
	if not supports(item.type):
		return Evaluation.incomplete()
	return _evaluators[item.type].evaluate(item, answer)


func solution_text(item: Item) -> String:
	return _evaluators[item.type].solution_text(item) if supports(item.type) else ""
