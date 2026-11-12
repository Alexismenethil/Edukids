extends GdUnitTestSuite
## Sonidos del juego: cada nombre del banco tiene su archivo y cada capítulo tiene su ambiente.


func test_every_sound_of_the_bank_exists() -> void:
	for sound in Sounds.NAMES:
		assert_bool(Sounds.has(sound)).override_failure_message("Falta el sonido «%s» (tools/audio/make_sfx.py)." % sound).is_true()


func test_an_unknown_sound_is_ignored() -> void:
	assert_bool(Sounds.has(&"trueno")).is_false()
	Sounds.play(&"trueno")


func test_every_chapter_has_its_ambience() -> void:
	for chapter: StringName in Chapter.STOPS:
		assert_bool(ResourceLoader.exists("res://assets/audio/ambience/amb_%s.ogg" % chapter)).override_failure_message(
			"Falta el ambiente de «%s»." % chapter).is_true()
