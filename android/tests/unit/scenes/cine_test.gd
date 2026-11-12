extends GdUnitTestSuite
## Elenco, clips de los personajes, mundos y cortos: revisa los datos que se escriben a mano, para
## que un hueso mal nombrado o un guion incompleto se detecten antes de abrir el juego.

const VOCABULARY: Array[StringName] = [&"neutral", &"happy", &"joy", &"laugh", &"wow", &"think", &"worry", &"sad", &"ouch",
	&"dizzy", &"proud", &"determined", &"sleepy"]


class _BrokenShort:
	extends ShortScript

	func beats() -> Array:
		return [
			{"cast": &"dragon"},
			{"play": &"quwi", "clip": &"wave"},
			{"dance": &"quwi"},
			{"cast": &"quwi"},
			{"fx": &"lasers", "on": &"quwi"},
			{"call": "missing_action"},
			{"say": &"quwi", "text": "  "},
			{"look": &"quwi", "at": &"nobody"},
		]


func _puppet(id: StringName) -> Puppet:
	var puppet := Cast.create(id, AvatarPalette.look_for({"body": "girl", "hair_style": 3}))
	add_child(puppet)
	return auto_free(puppet)


func test_every_cast_member_exists_and_is_a_puppet() -> void:
	assert_int(Cast.ids().size()).is_equal(Cast.ROSTER.size())
	for id in Cast.ids():
		var puppet := _puppet(id)
		assert_object(puppet).is_not_null()
		assert_bool(puppet.face != null).is_true()
		assert_float(Cast.size_of(id)).is_greater(0.0)


func test_an_unknown_cast_member_is_null() -> void:
	assert_bool(Cast.has(&"dragon")).is_false()


func test_every_clip_moves_bones_the_character_has() -> void:
	for id in Cast.ids():
		var puppet := _puppet(id)
		for clip_name in puppet.own_clips():
			var clip := puppet.own_clip(clip_name)
			for track in clip.tracks:
				if track.target != &"" and track.channel != PuppetClip.Channel.PARAM:
					assert_bool(puppet.has_bone(track.target)).override_failure_message(
						"%s: el clip «%s» mueve el hueso «%s», que no existe." % [id, clip_name, track.target]).is_true()
			for bone in clip.mute:
				assert_bool(bone == &"body" or puppet.has_bone(bone)).override_failure_message(
					"%s: el clip «%s» silencia «%s», que no existe." % [id, clip_name, bone]).is_true()


func test_every_clip_uses_faces_the_character_has() -> void:
	for id in Cast.ids():
		var puppet := _puppet(id)
		var faces := puppet.expressions()
		for clip_name in puppet.own_clips():
			for event: Array in puppet.own_clip(clip_name).events:
				if event[1] == "face" and str(event[2]) != "":
					assert_bool(StringName(event[2]) in faces).override_failure_message(
						"%s: el clip «%s» pide la cara «%s», que no existe." % [id, clip_name, event[2]]).is_true()


func test_every_character_has_the_basic_faces() -> void:
	for id in Cast.ids():
		var faces := _puppet(id).expressions()
		for face: StringName in [&"neutral", &"happy", &"wow"]:
			assert_bool(face in faces).override_failure_message("%s no tiene la cara «%s»." % [id, face]).is_true()


func test_tap_reactions_and_fidgets_are_real_clips() -> void:
	for id in Cast.ids():
		var puppet := _puppet(id)
		for clip_name in puppet.tap_reactions + puppet.fidgets:
			assert_bool(puppet.has_clip(clip_name)).override_failure_message(
				"%s: no existe el clip «%s»." % [id, clip_name]).is_true()


func test_library_faces_belong_to_the_common_vocabulary() -> void:
	for move in PuppetMoves.names():
		for event: Array in PuppetMoves.get_clip(move).events:
			if event[1] == "face" and str(event[2]) != "":
				assert_bool(StringName(event[2]) in VOCABULARY).is_true()


func test_every_mood_describes_the_same_things() -> void:
	var keys: Array = WorldSets.MOODS[&"day"].keys()
	for mood: StringName in WorldSets.MOODS:
		assert_array(WorldSets.MOODS[mood].keys()).contains_exactly_in_any_order(keys)


func test_every_short_in_the_catalog_is_well_written() -> void:
	assert_int(Shorts.ids().size()).is_equal(Shorts.CATALOG.size())
	for id in Shorts.ids():
		var script := Shorts.create(id)
		assert_str(String(script.id())).is_equal(String(id))
		assert_array(ShortLint.check(script)).override_failure_message(
			"Corto «%s»: %s" % [id, "; ".join(ShortLint.check(script))]).is_empty()


func test_shorts_keep_the_narrative_limit_of_four_bubbles() -> void:
	for id in Shorts.ids():
		var bubbles := 0
		for beat: Dictionary in Shorts.create(id).beats():
			if beat.has("say"):
				bubbles += 1
		assert_int(bubbles).is_less_equal(4)


func test_the_lint_finds_a_badly_written_short() -> void:
	var problems := ShortLint.check(_BrokenShort.new())
	assert_int(problems.size()).is_equal(7)
	assert_str(problems[0]).contains("no está en el elenco")
	assert_str(problems[1]).contains("todavía no entró")
	assert_str(problems[2]).contains("verbo conocido")
	assert_str(problems[3]).contains("efecto desconocido")
	assert_str(problems[4]).contains("no tiene la acción")
	assert_str(problems[5]).contains("no tiene texto")
	assert_str(problems[6]).contains("no está en el corto")


func test_an_unknown_short_is_null() -> void:
	assert_object(Shorts.create(&"moonwalk")).is_null()


func test_every_chapter_has_its_guide_and_its_running_world() -> void:
	for chapter: StringName in Chapter.STOPS:
		assert_bool(Cast.GUIDES.has(chapter)).is_true()
		assert_str(String(Cast.GUIDES[chapter])).is_equal(String(RegionStyle.guide_of(chapter)))
		assert_object(auto_free(Cast.guide_of(chapter))).is_not_null()
		assert_bool(WorldSets.REGION_WORLDS.has(chapter)).is_true()
		assert_str(RegionStyle.guide_name(chapter)).is_equal(Cast.display_name(Cast.GUIDES[chapter]))


func test_running_worlds_have_their_five_layers() -> void:
	for folder: String in [WorldSets.VALLEY + "valley", WorldSets.JUNGLE + "jungle", WorldSets.COAST + "coast"]:
		for layer: String in ["far", "mid", "near", "ground", "front"]:
			assert_bool(ResourceLoader.exists("%s_%s.svg" % [folder, layer])).override_failure_message(
				"Falta la capa %s_%s.svg" % [folder, layer]).is_true()


func test_an_unknown_chapter_falls_back_to_quwi() -> void:
	assert_str(String(RegionStyle.guide_of(&"luna"))).is_equal("quwi")
	assert_str(RegionStyle.name_of(&"selva")).is_equal("Selva")
