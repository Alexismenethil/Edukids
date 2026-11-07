class_name Attempt
extends RefCounted
## Intento de un estudiante en un nivel. Guarda la versión del paquete con la que se respondió
## (RN-05); un reintento crea otro intento y conserva el anterior (RF-24).

const PRACTICE := &"practice"
const FINAL := &"final"
const IN_PROGRESS := &"in_progress"
const COMPLETED := &"completed"
const GAME_OVER := &"game_over"
const CLOSED := &"closed"

var id := ""
var student_id := ""
## «paquete/nivel».
var level_key := ""
var package_version := ""
var kind: StringName = PRACTICE
var status: StringName = IN_PROGRESS
var started_at_ms := 0
var finished_at_ms := 0
var correct_count := 0
var total_count := 0
var percent := 0.0
var stars := 0
var cneb_grade := ""
var lives_lost := 0
var hints_used := 0


static func start(attempt_id: String, student: String, level: Level, now_ms: int) -> Attempt:
	var attempt := Attempt.new()
	attempt.id = attempt_id
	attempt.student_id = student
	attempt.level_key = level.key()
	attempt.package_version = level.package_version
	attempt.kind = FINAL if level.entry.kind == LevelEntry.FINAL else PRACTICE
	attempt.total_count = level.question_count()
	attempt.started_at_ms = now_ms
	return attempt


func is_open() -> bool:
	return status == IN_PROGRESS


func complete(summary: LevelSummary, now_ms: int) -> void:
	status = COMPLETED
	finished_at_ms = now_ms
	correct_count = summary.correct
	total_count = summary.total
	percent = summary.percent
	stars = summary.stars
	lives_lost = summary.lives_lost
	hints_used = summary.hints_used
