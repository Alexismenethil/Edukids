extends GdUnitTestSuite
## Bloqueo temporal tras 5 fallos seguidos (CU-03 y RNF-08).

const NOW := 1_794_009_600_000


func _fail(times: int, lockout: PinLockout = PinLockout.new(), at: int = NOW) -> PinLockout:
	for i in times:
		lockout = lockout.after_failure(at)
	return lockout


func test_starts_with_five_attempts() -> void:
	assert_int(PinLockout.new().attempts_left(NOW)).is_equal(5)
	assert_bool(PinLockout.new().is_locked(NOW)).is_false()


func test_four_failures_leave_one_attempt() -> void:
	var lockout := _fail(4)
	assert_int(lockout.attempts_left(NOW)).is_equal(1)
	assert_bool(lockout.is_locked(NOW)).is_false()


func test_fifth_failure_locks_for_five_minutes() -> void:
	var lockout := _fail(5)
	assert_bool(lockout.is_locked(NOW)).is_true()
	assert_int(lockout.remaining_ms(NOW)).is_equal(300_000)
	assert_int(lockout.attempts_left(NOW)).is_equal(0)
	assert_bool(lockout.is_locked(NOW + 299_999)).is_true()
	assert_bool(lockout.is_locked(NOW + 300_000)).is_false()


func test_failures_while_locked_do_not_extend_the_lock() -> void:
	var lockout := _fail(5)
	var later := lockout.after_failure(NOW + 60_000)
	assert_int(later.locked_until_ms).is_equal(lockout.locked_until_ms)


func test_after_the_lock_the_count_starts_again() -> void:
	var lockout := _fail(5)
	var after := NOW + 300_000
	assert_int(lockout.attempts_left(after)).is_equal(5)
	assert_int(lockout.after_failure(after).attempts_left(after)).is_equal(4)


func test_success_resets_the_count() -> void:
	assert_int(_fail(3).after_success().attempts_left(NOW)).is_equal(5)
