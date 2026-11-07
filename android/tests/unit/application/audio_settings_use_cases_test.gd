extends GdUnitTestSuite
## Casos de uso de sonido con dobles de prueba: sin SQLite ni AudioServer.

var _settings: FakeSettingsRepository
var _mixer: FakeAudioMixer


func before_test() -> void:
	_settings = FakeSettingsRepository.new()
	_mixer = FakeAudioMixer.new()


func test_restore_applies_the_saved_settings() -> void:
	_settings.stored = AudioSettings.new(0.3, 0.6, true)
	var response := RestoreAudioSettings.new(_settings, _mixer).execute()
	assert_bool(_mixer.last().equals(_settings.stored)).is_true()
	assert_bool(response.muted).is_true()


func test_toggle_mutes_saves_and_applies() -> void:
	var response := ToggleSound.new(_settings, _mixer).execute()
	assert_bool(response.muted).is_true()
	assert_bool(response.persisted).is_true()
	assert_bool(_settings.stored.muted).is_true()
	assert_bool(_mixer.last().muted).is_true()


func test_toggle_twice_restores_the_sound() -> void:
	var toggle := ToggleSound.new(_settings, _mixer)
	toggle.execute()
	assert_bool(toggle.execute().muted).is_false()
	assert_int(_settings.saves).is_equal(2)


func test_toggle_still_applies_when_saving_fails() -> void:
	_settings.fail_saves = true
	var response := ToggleSound.new(_settings, _mixer).execute()
	assert_bool(response.persisted).is_false()
	assert_bool(_mixer.last().muted).is_true()


func test_get_reads_without_applying() -> void:
	var response := GetAudioSettings.new(_settings).execute()
	assert_float(response.music_volume).is_equal_approx(0.7, 0.001)
	assert_array(_mixer.applied).is_empty()
