class_name ActivityFactory
extends RefCounted
## Elige la actividad que corresponde al tipo de ítem del paso.


static func create(step: StepViewModel) -> ActivityView:
	var view: ActivityView
	match step.type:
		"multiple_choice", "multi_select":
			view = ChoiceActivity.new()
		"true_false":
			view = TrueFalseActivity.new()
		"ordering":
			view = OrderingActivity.new()
		"matching":
			view = MatchingActivity.new()
		"classification":
			view = ClassificationActivity.new()
		"fill_blank":
			view = FillBlankActivity.new()
		"numeric":
			view = NumericActivity.new()
		_:
			return null
	view.setup(step)
	return view
