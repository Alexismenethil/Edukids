class_name CnebGradeScale
extends RefCounted
## Escala del desafío final (RN-12, RF-30).
##
## Por defecto: AD de 90 % a 100 %, A de 70 % a 89 %, B de 55 % a 69 % y C de 0 % a 54 %.
## El docente puede ajustar los mínimos de AD, A y B. La calificación es referencial.

const DEFAULT_MIN_AD := 90
const DEFAULT_MIN_A := 70
const DEFAULT_MIN_B := 55

var min_ad: int:
	get:
		return _min_ad

var min_a: int:
	get:
		return _min_a

var min_b: int:
	get:
		return _min_b

var _min_ad: int
var _min_a: int
var _min_b: int


func _init(ad_from: int = DEFAULT_MIN_AD, a_from: int = DEFAULT_MIN_A, b_from: int = DEFAULT_MIN_B) -> void:
	_min_ad = ad_from
	_min_a = a_from
	_min_b = b_from


## Crea una escala validando que 0 < B < A < AD ≤ 100.
static func create(ad_from: int, a_from: int, b_from: int) -> Result:
	if not (0 < b_from and b_from < a_from and a_from < ad_from and ad_from <= 100):
		return Result.fail(&"invalid_scale", "Los mínimos deben cumplir 0 < B < A < AD ≤ 100.")
	return Result.ok(CnebGradeScale.new(ad_from, a_from, b_from))


## Califica un desafío con sus aciertos. Compara con enteros para no depender de redondeos.
func grade(correct: int, total: int) -> CnebGrade:
	if total <= 0:
		return CnebGrade.new(CnebGrade.Achievement.C, 0.0)
	var hits := clampi(correct, 0, total)
	var percent := 100.0 * hits / total
	if hits * 100 >= _min_ad * total:
		return CnebGrade.new(CnebGrade.Achievement.AD, percent)
	if hits * 100 >= _min_a * total:
		return CnebGrade.new(CnebGrade.Achievement.A, percent)
	if hits * 100 >= _min_b * total:
		return CnebGrade.new(CnebGrade.Achievement.B, percent)
	return CnebGrade.new(CnebGrade.Achievement.C, percent)
