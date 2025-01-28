class_name GameField
extends Node2D

const END_MATCH_MUSIC_SCALE: float = 1.8

enum BattleMode {
	PLAYER_VS_COMPUTER,
	COMPUTER_VS_PLAYER,
	PLAYER_VS_PLAYER,
	COMPUTER_VS_COMPUTER,
}

@export var victory_score: int = 3

var _player_left_score: int = 0
var _player_right_score: int = 0

@onready var player_left_score_display: Label = %PlayerLeftScoreDisplay
@onready var player_right_score_display: Label = %PlayerRightScoreDisplay

@onready var player_left_paddle: Paddle = %PlayerLeftPaddle
@onready var player_right_paddle: Paddle = %PlayerRightPaddle

@onready var ball: CharacterBody2D = $Ball

@onready var background_music_player: AudioStreamPlayer2D = %BackgroundMusicPlayer
@onready var boundary_collision_sound: AudioStreamPlayer2D = %BoundaryCollisionSound
@onready var goal_scored_sound: AudioStreamPlayer2D = %GoalScoredSound
@onready var end_match_jingle: AudioStreamPlayer2D = %EndMatchJingle

@onready var game_pause_controller: Node2D = $GamePauseController
@onready var game_over_screen_overlay: CanvasLayer = %GameOverScreenOverlay
@onready var match_result_display: Label = %MatchResultDisplay

var _game_profile: GameProfile = GameProfile.new()


func _ready() -> void:
	_game_profile.load_profile()

	match _game_profile.battle_mode:
		BattleMode.PLAYER_VS_COMPUTER:
			player_left_paddle.player = Paddle.Player.PLAYER_A_HUMAN
			player_right_paddle.player = Paddle.Player.PLAYER_B_BOT
		BattleMode.COMPUTER_VS_PLAYER:
			player_left_paddle.player = Paddle.Player.PLAYER_A_BOT
			player_right_paddle.player = Paddle.Player.PLAYER_B_HUMAN
		BattleMode.PLAYER_VS_PLAYER:
			player_left_paddle.player = Paddle.Player.PLAYER_A_HUMAN
			player_right_paddle.player = Paddle.Player.PLAYER_B_HUMAN
		BattleMode.COMPUTER_VS_COMPUTER:
			player_left_paddle.player = Paddle.Player.PLAYER_A_BOT
			player_right_paddle.player = Paddle.Player.PLAYER_B_BOT

	victory_score = _game_profile.win_tally

	%ArenaTexture.texture = load(_game_profile.arena_texture_path)

	var arena_texture_name: String = (
		_game_profile.arena_texture_path.get_file().get_basename()
	)
	if arena_texture_name == "blue-arena":
		player_left_paddle.get_node("PaddleVisual").texture = load(
			"res://assets/graphics/paddles/yellow-paddle.png"
		)
		player_right_paddle.get_node("PaddleVisual").texture = load(
			"res://assets/graphics/paddles/grey-paddle.png"
		)
	else:
		player_left_paddle.get_node("PaddleVisual").texture = load(
			"res://assets/graphics/paddles/blue-paddle.png"
		)
		player_right_paddle.get_node("PaddleVisual").texture = load(
			"res://assets/graphics/paddles/yellow-paddle.png"
		)

	%PlayerLeftPaddle.prepare_paddle_for_play()
	%PlayerRightPaddle.prepare_paddle_for_play()

	var ball_texture: Texture2D = load(_game_profile.ball_texture_path)
	if ball_texture:
		ball.get_node("BallVisual").texture = ball_texture
		ball.start_new_ball_round()

	_adjust_sound_volumes()

	ball.boundary_collision.connect(_on_ball_boundary_collision)


func _on_ball_boundary_collision(collider: Node) -> void:
	boundary_collision_sound.play()


func _adjust_sound_volumes() -> void:
	var music_decibel_value: float = linear_to_db(_game_profile.music_volume / 10.0)
	var sfx_decibel_value: float = linear_to_db(_game_profile.sfx_volume / 10.0)

	background_music_player.volume_db = music_decibel_value
	boundary_collision_sound.volume_db = sfx_decibel_value
	goal_scored_sound.volume_db = sfx_decibel_value
	end_match_jingle.volume_db = sfx_decibel_value


func _on_player_left_net_body_entered(body: Node2D) -> void:
	if body is not Ball:
		return

	_player_right_score += 1
	player_right_score_display.text = str(_player_right_score)

	goal_scored_sound.play()

	if _player_right_score >= victory_score:
		_finalize_game_session()
	else:
		_reset_game_state()


func _on_player_right_net_body_entered(body: Node2D) -> void:
	if body is not Ball:
		return

	_player_left_score += 1
	player_left_score_display.text = str(_player_left_score)

	goal_scored_sound.play()

	if _player_left_score >= victory_score:
		_finalize_game_session()
	else:
		_reset_game_state()


func _finalize_game_session() -> void:
	var match_result: Dictionary = {
		"p1_control_type": player_left_paddle.get_player_control_type(),
		"p1_score": _player_left_score,
		"p2_control_type": player_right_paddle.get_player_control_type(),
		"p2_score": _player_right_score,
	}
	_game_profile.match_history.push_front(match_result)
	_game_profile.save_profile()

	get_tree().paused = true
	game_over_screen_overlay.visible = true
	game_pause_controller.set_game_ended(true)

	var victory_message: String
	if _player_left_score > _player_right_score:
		victory_message = "Player 1 wins!"
	else:
		victory_message = "Player 2 wins!"
	match_result_display.text = victory_message

	background_music_player.pitch_scale = END_MATCH_MUSIC_SCALE
	end_match_jingle.play()


func _reset_game_state() -> void:
	ball.start_new_ball_round()

	player_left_paddle.prepare_paddle_for_play()
	player_right_paddle.prepare_paddle_for_play()


func _on_rematch_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_to_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
