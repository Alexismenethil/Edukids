extends GdUnitTestSuite
## Un evaluador por tipo de ítem P1 y la validación del contenido de los paquetes.

var _registry: EvaluatorRegistry


func before_test() -> void:
	_registry = EvaluatorRegistry.standard()


func _item(raw: Dictionary) -> Item:
	var parsed := _registry.parse_item(raw)
	assert_bool(parsed.is_ok()).override_failure_message(parsed.message).is_true()
	return parsed.value


func test_registry_knows_the_p1_types() -> void:
	for type in ["multiple_choice", "multi_select", "true_false", "ordering", "matching",
			"classification", "fill_blank", "numeric", "reading_unit"]:
		assert_bool(_registry.supports(StringName(type))).override_failure_message(type).is_true()
	assert_bool(_registry.supports(&"simulation")).is_false()


func test_multiple_choice() -> void:
	var item := _item(SampleItems.multiple_choice())
	assert_bool(_registry.evaluate(item, "b").correct).is_true()
	var wrong := _registry.evaluate(item, "a")
	assert_bool(wrong.correct).is_false()
	assert_str(wrong.feedback).is_equal("Fíjate en la posición.")
	assert_str(item.feedback_for(_registry.evaluate(item, "c"))).is_equal("Revisa otra vez.")
	assert_bool(_registry.evaluate(item, "z").complete).is_false()
	assert_bool(_registry.evaluate(item, null).complete).is_false()
	assert_str(_registry.solution_text(item)).is_equal("50 000")


func test_multiple_choice_needs_exactly_one_correct_option() -> void:
	var raw := SampleItems.multiple_choice()
	raw["options"][0]["correct"] = true
	assert_str(_registry.parse_item(raw).error).is_equal("item_invalid")
	raw["options"] = [{"id": "a", "text": "Sola", "correct": true}]
	assert_str(_registry.parse_item(raw).error).is_equal("item_invalid")


func test_multi_select_needs_the_exact_set() -> void:
	var item := _item(SampleItems.multi_select())
	assert_bool(_registry.evaluate(item, ["a", "c"]).correct).is_true()
	assert_bool(_registry.evaluate(item, ["c", "a"]).correct).is_true()
	var partial := _registry.evaluate(item, ["a"])
	assert_bool(partial.correct).is_false()
	assert_int(partial.missing).is_equal(1)
	assert_dict(partial.parts).is_equal({"a": true})
	var extra := _registry.evaluate(item, ["a", "b", "c"])
	assert_bool(extra.correct).is_false()
	assert_str(extra.feedback).is_equal("14 ÷ 3 no es exacto.")
	assert_bool(_registry.evaluate(item, []).complete).is_false()
	assert_bool(_registry.evaluate(item, ["a", "a"]).complete).is_false()
	assert_str(_registry.solution_text(item)).is_equal("9, 21")


func test_true_false_checks_every_statement() -> void:
	var item := _item(SampleItems.true_false())
	assert_bool(_registry.evaluate(item, {"s1": true, "s2": false}).correct).is_true()
	var wrong := _registry.evaluate(item, {"s1": true, "s2": true})
	assert_bool(wrong.correct).is_false()
	assert_dict(wrong.parts).is_equal({"s1": true, "s2": false})
	assert_str(wrong.feedback).is_equal("El hielo es sólido.")
	assert_bool(_registry.evaluate(item, {"s1": true}).complete).is_false()
	assert_str(_registry.solution_text(item)).is_equal("1. Verdadero · 2. Falso")


func test_ordering_needs_the_identical_sequence() -> void:
	var item := _item(SampleItems.ordering())
	assert_bool(_registry.evaluate(item, ["y", "x", "z"]).correct).is_true()
	var wrong := _registry.evaluate(item, ["x", "y", "z"])
	assert_bool(wrong.correct).is_false()
	assert_dict(wrong.parts).is_equal({"x": false, "y": false, "z": true})
	assert_bool(_registry.evaluate(item, ["x", "y"]).complete).is_false()
	assert_bool(_registry.evaluate(item, ["x", "x", "z"]).complete).is_false()
	assert_str(_registry.solution_text(item)).is_equal("0,1 → 1/2 → 3")


func test_ordering_rejects_a_bad_correct_order() -> void:
	var raw := SampleItems.ordering()
	raw["correct_order"] = ["y", "x"]
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()
	raw["correct_order"] = ["y", "x", "w"]
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()


func test_matching_accepts_both_pair_styles() -> void:
	var item := _item(SampleItems.matching())
	assert_bool(_registry.evaluate(item, {"l1": "r2", "l2": "r1"}).correct).is_true()
	var wrong := _registry.evaluate(item, {"l1": "r2", "l2": "r3"})
	assert_dict(wrong.parts).is_equal({"l1": true, "l2": false})
	assert_bool(_registry.evaluate(item, {"l1": "r2"}).complete).is_false()
	assert_str(_registry.solution_text(item)).is_equal("1/2 ↔ 0,5 · 1/4 ↔ 0,25")


func test_matching_rejects_repeated_partners() -> void:
	var raw := SampleItems.matching()
	raw["pairs"] = [["l1", "r2"], ["l2", "r2"]]
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()


func test_classification_checks_each_element() -> void:
	var item := _item(SampleItems.classification())
	assert_bool(_registry.evaluate(item, {"n2": "even", "n7": "odd", "n10": "even"}).correct).is_true()
	var wrong := _registry.evaluate(item, {"n2": "even", "n7": "even", "n10": "even"})
	assert_dict(wrong.parts).is_equal({"n2": true, "n7": false, "n10": true})
	assert_bool(_registry.evaluate(item, {"n2": "even"}).complete).is_false()
	assert_str(_registry.solution_text(item)).is_equal("Pares: 2, 10 · Impares: 7")


func test_classification_groups_must_exist() -> void:
	var raw := SampleItems.classification()
	raw["elements"][0]["group"] = "prime"
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()


func test_fill_blank_compares_without_case_or_accents() -> void:
	var item := _item(SampleItems.fill_blank())
	assert_bool(_registry.evaluate(item, {"1": "Pero", "2": "porqué"}).correct).is_true()
	var wrong := _registry.evaluate(item, {"1": "y", "2": "porque"})
	assert_dict(wrong.parts).is_equal({"1": false, "2": true})
	assert_bool(_registry.evaluate(item, {"1": "pero", "2": "  "}).complete).is_false()
	assert_str(_registry.solution_text(item)).is_equal("Quería salir, pero llovía. Me quedé porque estaba cansada.")


func test_fill_blank_markers_must_match_the_blanks() -> void:
	var raw := SampleItems.fill_blank()
	raw["text"] = "Solo {{1}} aquí."
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()
	raw = SampleItems.fill_blank()
	raw["blanks"][0]["options"] = ["y", "o"]
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()


func test_fill_blank_splits_its_text() -> void:
	var tokens := FillBlankEvaluator.split_text("A {{1}} B {{ 2 }}")
	assert_array(tokens).is_equal([{"text": "A "}, {"blank": "1"}, {"text": " B "}, {"blank": "2"}])


func test_numeric_accepts_equivalent_formats() -> void:
	var item := _item(SampleItems.numeric())
	for text in ["0,5", "0.5", "1/2", "2/4"]:
		assert_bool(_registry.evaluate(item, text).correct).override_failure_message(text).is_true()
	assert_bool(_registry.evaluate(item, "0,6").correct).is_false()
	assert_bool(_registry.evaluate(item, "").complete).is_false()
	assert_bool(_registry.evaluate(item, "1/0").complete).is_false()


func test_numeric_only_takes_the_formats_of_the_item() -> void:
	var item := _item(SampleItems.numeric("nu", ["decimal"]))
	assert_bool(_registry.evaluate(item, "0,5").correct).is_true()
	assert_bool(_registry.evaluate(item, "1/2").correct).is_false()


func test_numeric_tolerance_and_unit() -> void:
	var raw := SampleItems.numeric()
	raw["answer"] = 1440
	raw["tolerance"] = 5
	raw["unit"] = "S/"
	var item := _item(raw)
	assert_bool(_registry.evaluate(item, "1 444").correct).is_true()
	assert_bool(_registry.evaluate(item, "1 446").correct).is_false()
	assert_str(_registry.solution_text(item)).is_equal("S/ 1 440")
	raw["unit"] = "litros"
	assert_str(_registry.solution_text(_item(raw))).is_equal("1 440 litros")


func test_numeric_rejects_bad_settings() -> void:
	var raw := SampleItems.numeric()
	raw["answer"] = "medio"
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()
	raw = SampleItems.numeric()
	raw["accepted_formats"] = ["roman"]
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()


func test_reading_unit_evaluates_each_question() -> void:
	var item := _item(SampleItems.reading_unit())
	assert_int(item.spec["items"].size()).is_equal(2)
	assert_array(item.spec["stimulus"]["paragraphs"]).is_equal(["Primer párrafo.", "Segundo párrafo."])
	var right := _registry.evaluate(item, {"ru-1": "b", "ru-2": {"s1": true, "s2": false}})
	assert_bool(right.correct).is_true()
	var wrong := _registry.evaluate(item, {"ru-1": "a", "ru-2": {"s1": true, "s2": false}})
	assert_dict(wrong.parts).is_equal({"ru-1": false, "ru-2": true})
	assert_bool(_registry.evaluate(item, {"ru-1": "b"}).complete).is_false()


func test_reading_unit_with_a_table() -> void:
	var raw := SampleItems.reading_unit()
	raw["stimulus"] = {"type": "table", "title": "Lluvias", "content": {
		"columns": ["Mes", "mm"], "rows": [["Enero", 120], ["Julio", 4]]}}
	var item := _item(raw)
	assert_array(item.spec["stimulus"]["rows"]).is_equal([["Enero", "120"], ["Julio", "4"]])
	raw["stimulus"]["content"]["rows"] = [["Enero"]]
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()


func test_reading_units_cannot_be_nested() -> void:
	var raw := SampleItems.reading_unit()
	raw["items"] = [SampleItems.reading_unit("inner")]
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()


func test_common_fields_are_required() -> void:
	var raw := SampleItems.multiple_choice()
	raw.erase("feedback")
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()
	raw = SampleItems.multiple_choice()
	raw["prompt"] = "  "
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()
	raw = SampleItems.multiple_choice()
	raw["type"] = "simulation"
	assert_bool(_registry.parse_item(raw).is_ok()).is_false()
	assert_bool(_registry.parse_item("texto").is_ok()).is_false()
