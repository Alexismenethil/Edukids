extends GdUnitTestSuite
## RF-36: volumen de música y de efectos por separado, y silencio general.


func test_defaults() -> void:
	var settings := AudioSettings.defaults()
	assert_float(settings.music_volume).is_equal_approx(0.7, 0.001)
	assert_float(settings.sfx_volume).is_equal_approx(0.9, 0.001)
	assert_bool(settings.muted).is_false()


func test_volumes_stay_between_zero_and_one() -> void:
	var settings := AudioSettings.new(1.4, -0.3)
	assert_float(settings.music_volume).is_equal(1.0)
	assert_float(settings.sfx_volume).is_equal(0.0)


func test_toggling_creates_a_new_value() -> void:
	var original := AudioSettings.defaults()
	var muted := original.toggled_mute()
	assert_bool(muted.muted).is_true()
	assert_bool(original.muted).is_false()
	assert_bool(muted.toggled_mute().equals(original)).is_true()


func test_volumes_change_independently() -> void:
	var settings := AudioSettings.defaults().with_music_volume(0.2).with_sfx_volume(0.5)
	assert_float(settings.music_volume).is_equal_approx(0.2, 0.001)
	assert_float(settings.sfx_volume).is_equal_approx(0.5, 0.001)


func test_audible_only_when_not_muted_and_some_volume() -> void:
	assert_bool(AudioSettings.defaults().is_audible()).is_true()
	assert_bool(AudioSettings.defaults().toggled_mute().is_audible()).is_false()
	assert_bool(AudioSettings.new(0.0, 0.0).is_audible()).is_false()
