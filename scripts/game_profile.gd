class_name GameProfile
extends Resource

const SAVE_PATH: String = "user://game_profile.tres"

@export var music_volume: float = 100.0
@export var sfx_volume: float = 100.0

@export var match_history: Array[Dictionary] = []


func save_profile() -> void:
	var error: Error = ResourceSaver.save(self, SAVE_PATH)
	if error:
		printerr("Failed to save the game profile: %s" % error)


func load_profile() -> void:
	if not ResourceLoader.exists(SAVE_PATH):
		return

	var loaded_settings: GameProfile = ResourceLoader.load(SAVE_PATH)

	music_volume = loaded_settings.music_volume
	sfx_volume = loaded_settings.sfx_volume

	match_history = loaded_settings.match_history
