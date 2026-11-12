extends GdUnitTestSuite
## Motor de títeres: curvas, clips, reproducción, resortes y la biblioteca de gestos. Son las
## piezas que no dependen de la pantalla; el resto se revisa en el laboratorio de personajes.

const WAVE := {
	"group": &"arms",
	"mute": [&"arm_r"],
	"tracks": {
		"arm_r:rot": [[0.2, -2.0, "linear"], [0.6, -2.0], [1.0, 0.0, "linear"]],
		"squash": [[0.5, [1.2, 0.8], "linear"], [1.0, [1.0, 1.0], "linear"]],
		"face": [[0.0, "happy"], [0.8, ""]],
		"cue": [[0.3, "squeak"]],
		"emote": [[0.5, "heart"]],
	},
}


func test_every_curve_starts_at_zero_and_ends_at_one(kind: StringName, test_parameters := [
	[&"linear"], [&"in"], [&"out"], [&"inout"], [&"cubic"], [&"snap"], [&"back"], [&"elastic"], [&"bounce"],
]) -> void:
	assert_float(PuppetEase.apply(kind, 0.0)).is_equal_approx(0.0, 0.001)
	assert_float(PuppetEase.apply(kind, 1.0)).is_equal_approx(1.0, 0.001)


func test_hold_waits_until_the_end() -> void:
	assert_float(PuppetEase.apply(&"hold", 0.99)).is_equal(0.0)
	assert_float(PuppetEase.apply(&"hold", 1.0)).is_equal(1.0)


func test_back_overshoots_before_settling() -> void:
	assert_float(PuppetEase.apply(&"back", 0.7)).is_greater(1.0)


func test_a_clip_reads_its_tracks_and_length() -> void:
	var clip := PuppetClip.from_dict(&"wave", WAVE)
	assert_float(clip.length).is_equal_approx(1.0, 0.0001)
	assert_int(clip.tracks.size()).is_equal(2)
	assert_int(clip.events.size()).is_equal(4)
	assert_str(String(clip.group)).is_equal("arms")
	assert_array(clip.mute).contains_exactly([&"arm_r"])


func test_a_track_starts_from_rest_and_holds_its_last_key() -> void:
	var clip := PuppetClip.from_dict(&"wave", WAVE)
	var arm: PuppetClip.Track = clip.tracks[0]
	assert_float(arm.sample(0.0)).is_equal_approx(0.0, 0.0001)
	assert_float(arm.sample(0.1)).is_equal_approx(-1.0, 0.0001)
	assert_float(arm.sample(0.4)).is_equal_approx(-2.0, 0.0001)
	assert_float(arm.sample(0.8)).is_equal_approx(-1.0, 0.0001)
	assert_float(arm.sample(5.0)).is_equal_approx(0.0, 0.0001)


func test_scale_tracks_rest_at_one() -> void:
	var clip := PuppetClip.from_dict(&"wave", WAVE)
	var squash: PuppetClip.Track = clip.tracks[1]
	assert_bool(squash.multiply).is_true()
	assert_vector(squash.sample(0.0)).is_equal_approx(Vector2.ONE, Vector2(0.0001, 0.0001))
	assert_vector(squash.sample(0.25)).is_equal_approx(Vector2(1.1, 0.9), Vector2(0.0001, 0.0001))


func test_an_unknown_track_is_skipped() -> void:
	var clip := PuppetClip.from_dict(&"odd", {"tracks": {"arm_r:wobble": [[0.2, 1.0]], "lift": [[0.2, 10.0]]}})
	assert_int(clip.tracks.size()).is_equal(1)


func test_playback_fires_each_event_once_and_keeps_the_face() -> void:
	var playback := PuppetPlayback.new(PuppetClip.from_dict(&"wave", WAVE))
	var fired: Array = []
	for i in 10:
		fired.append_array(playback.advance(0.1))
		if i == 3:
			assert_str(String(playback.face)).is_equal("happy")
	assert_array(fired).contains_exactly([["cue", "squeak"], ["emote", "heart"]])
	assert_str(String(playback.face)).is_equal("")


func test_playback_fades_out_and_finishes() -> void:
	var playback := PuppetPlayback.new(PuppetClip.from_dict(&"wave", WAVE))
	var finished := [false]
	playback.finished.connect(func() -> void: finished[0] = true)
	for i in 10:
		playback.advance(0.1)
	assert_bool(playback.done).is_false()
	for i in 4:
		playback.advance(0.1)
	assert_bool(playback.done).is_true()
	assert_bool(finished[0]).is_true()
	assert_float(playback.weight).is_equal(0.0)


func test_stop_cuts_a_clip_early() -> void:
	var playback := PuppetPlayback.new(PuppetClip.from_dict(&"wave", WAVE))
	playback.advance(0.2)
	playback.stop(0.1)
	playback.advance(0.05)
	assert_float(playback.weight).is_equal_approx(0.5, 0.01)
	playback.advance(0.1)
	assert_bool(playback.done).is_true()


func test_a_looping_clip_repeats_its_events() -> void:
	var playback := PuppetPlayback.new(PuppetClip.from_dict(&"wave", WAVE))
	playback.loop = true
	var cues := 0
	for i in 25:
		for event: Array in playback.advance(0.1):
			if event[0] == "cue":
				cues += 1
	assert_bool(playback.done).is_false()
	assert_int(cues).is_greater_equal(2)


func test_a_spring_rests_when_nothing_moves() -> void:
	var spring := PuppetSpring.new()
	for i in 30:
		spring.step(Vector2.ZERO, Vector2(0, 60), Vector2.ZERO, false, 1.0 / 60.0)
	assert_float(spring.angle).is_equal_approx(0.0, 0.0001)


func test_a_spring_lags_behind_and_settles() -> void:
	var spring := PuppetSpring.new()
	spring.step(Vector2.ZERO, Vector2(0, 60), Vector2.ZERO, false, 1.0 / 60.0)
	# El personaje salta 40 píxeles a la derecha: la punta se queda atrás (a la izquierda).
	var moved := Vector2(40, 0)
	spring.step(moved, moved + Vector2(0, 60), Vector2.ZERO, false, 1.0 / 60.0)
	assert_float(spring.angle).is_greater(0.2)
	for i in 240:
		spring.step(moved, moved + Vector2(0, 60), Vector2.ZERO, false, 1.0 / 60.0)
	assert_float(absf(spring.angle)).is_less(0.01)


func test_a_spring_never_passes_its_limit_and_stays_stable_at_low_frame_rates() -> void:
	var spring := PuppetSpring.new()
	spring.limit = 0.5
	var pivot := Vector2.ZERO
	for i in 200:
		pivot += Vector2(90.0 if i % 7 < 3 else -120.0, 30.0 * sin(i))
		spring.step(pivot, pivot + Vector2(0, 60), Vector2(-400, 0), false, 1.0 / 20.0)
		assert_float(absf(spring.angle)).is_less_equal(0.5001)
		assert_bool(is_nan(spring.angle)).is_false()


func test_a_mirrored_spring_turns_the_other_way() -> void:
	var normal := PuppetSpring.new()
	var mirrored := PuppetSpring.new()
	for spring: PuppetSpring in [normal, mirrored]:
		spring.step(Vector2.ZERO, Vector2(0, 60), Vector2.ZERO, spring == mirrored, 1.0 / 60.0)
		spring.step(Vector2(40, 0), Vector2(40, 60), Vector2.ZERO, spring == mirrored, 1.0 / 60.0)
	assert_float(mirrored.angle).is_equal_approx(-normal.angle, 0.0001)


func test_wind_bends_a_spring_downwind() -> void:
	var spring := PuppetSpring.new()
	spring.drag = 0.05
	for i in 240:
		spring.step(Vector2.ZERO, Vector2(0, 60), Vector2(-600, 0), false, 1.0 / 60.0)
	# El viento va hacia la izquierda: la punta que cuelga se va a la izquierda (giro positivo).
	assert_float(spring.angle).is_greater(0.3)


func test_the_library_compiles_every_move(move: StringName, test_parameters := [
	[&"hop"], [&"cheer"], [&"flip"], [&"nod"], [&"shake"], [&"startle"], [&"flinch"], [&"shiver"], [&"wiggle"],
	[&"laugh"], [&"dizzy"], [&"proud"], [&"sigh"], [&"look_around"], [&"ponder"], [&"stretch"],
]) -> void:
	var clip := PuppetMoves.get_clip(move)
	assert_object(clip).is_not_null()
	assert_float(clip.length).is_greater(0.2)
	assert_bool(clip.tracks.is_empty()).is_false()


func test_library_moves_only_use_the_body_and_the_gaze() -> void:
	for move in PuppetMoves.names():
		for track in PuppetMoves.get_clip(move).tracks:
			assert_str(String(track.target)).is_equal("")


func test_an_unknown_move_is_null() -> void:
	assert_object(PuppetMoves.get_clip(&"moonwalk")).is_null()
