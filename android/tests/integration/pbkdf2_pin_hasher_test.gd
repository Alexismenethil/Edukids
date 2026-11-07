extends GdUnitTestSuite
## Integración: hash de los PIN con PBKDF2-HMAC-SHA256 (RNF-08).


func test_matches_the_published_test_vectors() -> void:
	var hasher := Pbkdf2PinHasher.new()
	var password := "password".to_utf8_buffer()
	var salt := "salt".to_utf8_buffer()
	assert_str(hasher.derive(password, salt, 1).hex_encode()).is_equal("120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b")
	assert_str(hasher.derive(password, salt, 2).hex_encode()).is_equal("ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43")
	assert_str(hasher.derive(password, salt, 4096).hex_encode()).is_equal("c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a")


func test_hash_records_algorithm_and_iterations() -> void:
	var hasher := Pbkdf2PinHasher.new()
	var salt := hasher.new_salt()
	assert_int(salt.length()).is_equal(32)
	var hashed := hasher.hash_pin("4702", salt)
	assert_str(hashed).starts_with("pbkdf2-sha256$4000$")
	assert_bool(hashed.contains("4702")).is_false()


func test_verifies_only_the_right_pin() -> void:
	var hasher := Pbkdf2PinHasher.new()
	var salt := hasher.new_salt()
	var credential := PinCredential.new(hasher.hash_pin("4702", salt), salt)
	assert_bool(hasher.verify("4702", credential)).is_true()
	assert_bool(hasher.verify("4703", credential)).is_false()
	assert_bool(hasher.verify("4702", PinCredential.new("otro$1$00", salt))).is_false()


func test_same_pin_with_another_salt_gives_another_hash() -> void:
	var hasher := Pbkdf2PinHasher.new()
	assert_str(hasher.hash_pin("4702", hasher.new_salt())).is_not_equal(hasher.hash_pin("4702", hasher.new_salt()))


func test_old_hashes_keep_working_if_iterations_change() -> void:
	var old := Pbkdf2PinHasher.new(1000)
	var salt := old.new_salt()
	var credential := PinCredential.new(old.hash_pin("8315", salt), salt)
	assert_bool(Pbkdf2PinHasher.new(8000).verify("8315", credential)).is_true()


func test_hashing_is_fast_enough_for_a_tablet() -> void:
	var hasher := Pbkdf2PinHasher.new()
	var salt := hasher.new_salt()
	var started := Time.get_ticks_usec()
	hasher.hash_pin("4702", salt)
	var elapsed_ms := (Time.get_ticks_usec() - started) / 1000.0
	print("PBKDF2 con %d iteraciones: %.1f ms" % [Pbkdf2PinHasher.ITERATIONS, elapsed_ms])
	assert_float(elapsed_ms).is_less(250.0)
