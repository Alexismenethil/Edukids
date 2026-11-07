class_name SqliteAttemptRepository
extends AttemptRepository
## Adaptador de salida: intentos y respuestas en SQLite. Cada respuesta es una sola sentencia,
## que SQLite guarda como su propia transacción (RNF-06, modo WAL).

const ATTEMPT_COLUMNS := "id, student_id, level_id, package_version, kind, status, started_at, finished_at, correct_count, total_count, percent, stars, cneb_grade, lives_lost, hints_used"
const ANSWER_COLUMNS := "id, attempt_id, item_id, value_json, is_correct, first_try, with_hint, time_ms, answered_at"

var _database: SqliteDatabase


func _init(database: SqliteDatabase) -> void:
	_database = database


func create_attempt(attempt: Attempt) -> Result:
	return _database.execute(
		"INSERT INTO attempt (id, student_id, level_id, package_version, kind, status, started_at, total_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
		[attempt.id, attempt.student_id, attempt.level_key, attempt.package_version, String(attempt.kind),
			String(attempt.status), IsoTime.from_unix_ms(attempt.started_at_ms), attempt.total_count])


func save_answer(answer: AttemptAnswer) -> Result:
	return _database.execute(
		"INSERT INTO answer (%s) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);" % ANSWER_COLUMNS,
		[answer.id, answer.attempt_id, answer.item_id, JSON.stringify(answer.value), 1 if answer.is_correct else 0,
			1 if answer.first_try else 0, 1 if answer.with_hint else 0, answer.time_ms,
			IsoTime.from_unix_ms(answer.answered_at_ms)])


func finish_attempt(attempt: Attempt) -> Result:
	return _database.execute(
		"UPDATE attempt SET status = ?, finished_at = ?, correct_count = ?, total_count = ?, percent = ?, stars = ?, lives_lost = ?, hints_used = ? WHERE id = ?;",
		[String(attempt.status), IsoTime.from_unix_ms(attempt.finished_at_ms), attempt.correct_count,
			attempt.total_count, attempt.percent, attempt.stars, attempt.lives_lost, attempt.hints_used, attempt.id])


func find_open_attempt(student_id: String, level_key: String) -> Attempt:
	var rows := _database.query(
		"SELECT %s FROM attempt WHERE student_id = ? AND level_id = ? AND status = 'in_progress' ORDER BY started_at DESC, rowid DESC LIMIT 1;" % ATTEMPT_COLUMNS,
		[student_id, level_key])
	if not rows.is_ok() or (rows.value as Array).is_empty():
		return null
	return _to_attempt(rows.value[0])


func list_answers(attempt_id: String) -> Array[AttemptAnswer]:
	var answers: Array[AttemptAnswer] = []
	var rows := _database.query("SELECT %s FROM answer WHERE attempt_id = ? ORDER BY rowid;" % ANSWER_COLUMNS, [attempt_id])
	if not rows.is_ok():
		return answers
	for row: Dictionary in rows.value:
		var answer := AttemptAnswer.new()
		answer.id = str(row["id"])
		answer.attempt_id = str(row["attempt_id"])
		answer.item_id = str(row["item_id"])
		answer.value = JSON.parse_string(str(row["value_json"]))
		answer.is_correct = int(row["is_correct"]) == 1
		answer.first_try = int(row["first_try"]) == 1
		answer.with_hint = int(row["with_hint"]) == 1
		answer.time_ms = int(row["time_ms"])
		answer.answered_at_ms = IsoTime.to_unix_ms(row["answered_at"])
		answers.append(answer)
	return answers


func best_stars(student_id: String) -> Dictionary:
	var best := {}
	var rows := _database.query(
		"SELECT level_id, MAX(stars) AS best FROM attempt WHERE student_id = ? AND status = 'completed' GROUP BY level_id;",
		[student_id])
	if rows.is_ok():
		for row: Dictionary in rows.value:
			best[str(row["level_id"])] = int(row["best"]) if row["best"] != null else 0
	return best


static func _to_attempt(row: Dictionary) -> Attempt:
	var attempt := Attempt.new()
	attempt.id = str(row["id"])
	attempt.student_id = str(row["student_id"])
	attempt.level_key = str(row["level_id"])
	attempt.package_version = str(row["package_version"])
	attempt.kind = StringName(str(row["kind"]))
	attempt.status = StringName(str(row["status"]))
	attempt.started_at_ms = IsoTime.to_unix_ms(row["started_at"])
	attempt.finished_at_ms = IsoTime.to_unix_ms(row["finished_at"])
	attempt.correct_count = int(row["correct_count"])
	attempt.total_count = int(row["total_count"])
	attempt.percent = float(row["percent"]) if row["percent"] != null else 0.0
	attempt.stars = int(row["stars"]) if row["stars"] != null else 0
	attempt.cneb_grade = str(row["cneb_grade"]) if row["cneb_grade"] != null else ""
	attempt.lives_lost = int(row["lives_lost"])
	attempt.hints_used = int(row["hints_used"])
	return attempt
