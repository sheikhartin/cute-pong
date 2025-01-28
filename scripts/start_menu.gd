extends CanvasLayer

const SMALL_PREVIEW_SIZE: Vector2i = Vector2i(20, 20)

@onready var start_screen_layout: VBoxContainer = %StartScreenLayout
@onready var pre_game_menu_layout: VBoxContainer = %PreGameMenuLayout
@onready var game_settings_layout: VBoxContainer = %GameSettingsLayout
@onready var history_display_layout: VBoxContainer = %HistoryDisplayLayout

@onready var main_menu_return_button: Button = %MainMenuReturnButton

@onready var background_music_player: AudioStreamPlayer2D = %BackgroundMusicPlayer
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = %SFXVolumeSlider

const BATTLE_MODES: Dictionary = {
	"Human 👤 vs. computer 🤖": GameField.BattleMode.PLAYER_VS_COMPUTER,
	"Computer 🤖 vs. human 👤": GameField.BattleMode.COMPUTER_VS_PLAYER,
	"Human 👤 vs. human 👤": GameField.BattleMode.PLAYER_VS_PLAYER,
	"Computer 🤖 vs. computer 🤖": GameField.BattleMode.COMPUTER_VS_COMPUTER,
}

const ARENA_TEXTURES: Dictionary = {
	"Green": "res://assets/graphics/arenas/green-arena.png",
	"Blue": "res://assets/graphics/arenas/blue-arena.png",
	"Orange": "res://assets/graphics/arenas/orange-arena.png"
}

const BALL_TEXTURES: Dictionary = {
	"Red": "res://assets/graphics/balls/large-red-ball.png",
	"Red alt.": "res://assets/graphics/balls/small-red-ball-alt.png",
	"Blue": "res://assets/graphics/balls/large-blue-ball.png",
	"Blue alt.": "res://assets/graphics/balls/small-blue-ball-alt.png",
	"Green circle": "res://assets/graphics/balls/green-body-circle.png",
	"Green square": "res://assets/graphics/balls/green-body-square.png",
	"Purple circle": "res://assets/graphics/balls/purple-body-circle.png",
	"Purple square": "res://assets/graphics/balls/purple-body-square.png",
	"Pink circle": "res://assets/graphics/balls/pink-body-circle.png",
	"Pink square": "res://assets/graphics/balls/pink-body-square.png",
	"Yellow circle": "res://assets/graphics/balls/yellow-body-circle.png",
	"Yellow square": "res://assets/graphics/balls/yellow-body-square.png",
}

var _game_profile: GameProfile = GameProfile.new()


func _ready() -> void:
	_game_profile.load_profile()

	_adjust_sound_volumes()


func _adjust_sound_volumes() -> void:
	background_music_player.volume_db = linear_to_db(
		_game_profile.music_volume / 10.0
	)


func generate_thumbnail(source_path: String) -> Texture2D:
	var source_texture: Texture2D = load(source_path)
	var thumbnail_image: Image = source_texture.get_image()
	thumbnail_image.resize(
		SMALL_PREVIEW_SIZE.x, SMALL_PREVIEW_SIZE.y, Image.INTERPOLATE_BILINEAR
	)
	return ImageTexture.create_from_image(thumbnail_image)


func _on_play_game_button_pressed() -> void:
	start_screen_layout.visible = false
	main_menu_return_button.show()

	%BattleModeOption.clear()
	for battle_mode in BATTLE_MODES.keys():
		%BattleModeOption.add_item(battle_mode)

	var default_battle_mode_index: int = BATTLE_MODES.keys().find(
		BATTLE_MODES.find_key(_game_profile.battle_mode)
	)
	if default_battle_mode_index != -1:
		%BattleModeOption.select(default_battle_mode_index)

	%WinTally.value = _game_profile.win_tally

	%ArenaTextureOption.clear()
	for arena_name in ARENA_TEXTURES.keys():
		var thumbnail: Texture2D = generate_thumbnail(ARENA_TEXTURES[arena_name])
		%ArenaTextureOption.add_icon_item(thumbnail, arena_name)

	var default_arena_index: int = ARENA_TEXTURES.keys().find(
		ARENA_TEXTURES.find_key(_game_profile.arena_texture_path)
	)
	if default_arena_index != -1:
		%ArenaTextureOption.select(default_arena_index)

	%BallTextureOption.clear()
	for ball_name in BALL_TEXTURES.keys():
		var thumbnail: Texture2D = generate_thumbnail(BALL_TEXTURES[ball_name])
		%BallTextureOption.add_icon_item(thumbnail, ball_name)

	var default_ball_index: int = BALL_TEXTURES.keys().find(
		BALL_TEXTURES.find_key(_game_profile.ball_texture_path)
	)
	if default_ball_index != -1:
		%BallTextureOption.select(default_ball_index)

	pre_game_menu_layout.visible = true


func _on_config_button_pressed() -> void:
	start_screen_layout.visible = false
	main_menu_return_button.show()

	music_volume_slider.value = _game_profile.music_volume
	sfx_volume_slider.value = _game_profile.sfx_volume

	game_settings_layout.visible = true


func _on_game_history_button_pressed() -> void:
	start_screen_layout.visible = false
	main_menu_return_button.show()

	for child in %HistoryList.get_children():
		child.queue_free()

	for match_result in _game_profile.match_history:
		var result_label: Label = Label.new()
		result_label.text = (
			"(%s) %d - %d (%s)"
			% [
				match_result["p1_control_type"],
				match_result["p1_score"],
				match_result["p2_score"],
				match_result["p2_control_type"]
			]
		)
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_label.add_theme_font_size_override("font_size", 30)
		%HistoryList.add_child(result_label)

	history_display_layout.visible = true


func _on_quit_game_button_pressed() -> void:
	get_tree().quit()


func _on_main_menu_return_button_pressed() -> void:
	pre_game_menu_layout.visible = false
	game_settings_layout.visible = false
	history_display_layout.visible = false
	main_menu_return_button.hide()

	start_screen_layout.visible = true


func _on_start_button_pressed() -> void:
	_game_profile.battle_mode = BATTLE_MODES[%BattleModeOption.get_item_text(
		%BattleModeOption.selected
	)]

	_game_profile.win_tally = %WinTally.value

	_game_profile.arena_texture_path = ARENA_TEXTURES[
		%ArenaTextureOption.get_item_text(%ArenaTextureOption.selected)
	]
	_game_profile.ball_texture_path = BALL_TEXTURES[%BallTextureOption.get_item_text(
		%BallTextureOption.selected
	)]
	_game_profile.save_profile()

	get_tree().change_scene_to_file("res://scenes/game_field.tscn")


func _on_music_volume_slider_value_changed(value: float) -> void:
	_game_profile.music_volume = value
	_game_profile.save_profile()

	_adjust_sound_volumes()


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	_game_profile.sfx_volume = value
	_game_profile.save_profile()
