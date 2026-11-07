extends GdUnitTestSuite
## Avatar del estudiante (RF-31).

const TRAITS := {"body": "girl", "skin": 2, "hair_style": 3, "hair_color": 0, "top_color": 1, "bottom_color": 4}


func test_creates_a_valid_avatar() -> void:
	var avatar: Avatar = Avatar.create(TRAITS).value
	assert_str(String(avatar.body)).is_equal("girl")
	assert_int(avatar.skin).is_equal(2)
	assert_int(avatar.hair_style).is_equal(3)
	assert_dict(avatar.to_dict()).is_equal(TRAITS)


func test_rejects_unknown_body_or_traits() -> void:
	var traits := TRAITS.duplicate()
	traits["body"] = "robot"
	assert_str(Avatar.create(traits).error).is_equal("avatar_body")
	traits = TRAITS.duplicate()
	traits["skin"] = Avatar.SKIN_TONES
	assert_str(Avatar.create(traits).error).is_equal("avatar_trait")
	traits = TRAITS.duplicate()
	traits.erase("hair_color")
	assert_str(Avatar.create(traits).error).is_equal("avatar_trait")
	traits = TRAITS.duplicate()
	traits["top_color"] = 1.5
	assert_str(Avatar.create(traits).error).is_equal("avatar_trait")


func test_reads_back_from_json() -> void:
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(TRAITS))
	assert_bool(Avatar.from_dict(parsed).equals(Avatar.create(TRAITS).value)).is_true()


func test_empty_json_means_not_created_yet() -> void:
	assert_object(Avatar.from_dict({})).is_null()
	assert_object(Avatar.from_dict({"body": "girl"})).is_null()
