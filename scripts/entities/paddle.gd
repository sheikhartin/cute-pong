class_name Paddle
extends CharacterBody2D

@export var edge_margin: float = 25.0

@export var initial_paddle_velocity: float = 2300.0
@export var slowdown_intensity: float = 6.0
@export var velocity_boost_rate: float = 1.15

var _current_movement_speed: float = initial_paddle_velocity

enum Player {
	PLAYER_A_HUMAN,
	PLAYER_A_BOT,
	PLAYER_B_HUMAN,
	PLAYER_B_BOT,
}

@export var player: Player = Player.PLAYER_A_HUMAN
@export var custom_texture: Texture2D

@export var initial_paddle_scale: float = 0.28
@export var minimum_scale: float = initial_paddle_scale * 0.5

@export var scale_reduction_rate: float = 0.8
@onready var shrink_timer: Timer = $ShrinkTimer
@export var shrink_delay: float = 10.0

@onready var paddle_visual: Sprite2D = $PaddleVisual
@onready var paddle_hitbox: CollisionShape2D = $PaddleHitbox

@onready var paddle_hit_sound: AudioStreamPlayer2D = $PaddleHitSound

var _ball: Ball

var _display_bounds: Vector2
var _screen_width_half: float
var _screen_width_quarter: float


func _ready() -> void:
	if custom_texture:
		paddle_visual.texture = custom_texture

	prepare_paddle_for_play()

	if player == Player.PLAYER_B_HUMAN or player == Player.PLAYER_B_BOT:
		paddle_visual.flip_v = true

	_adjust_screen_partition_markers(get_viewport_rect().size)
	# get_viewport().size_changed.connect(_adjust_screen_partition_markers)

	_ball = get_tree().get_root().find_child("Ball", true, false)
	if _ball:
		_ball.paddle_collision.connect(_on_ball_paddle_collision)


func _physics_process(delta: float) -> void:
	velocity -= velocity * delta * slowdown_intensity

	match player:
		Player.PLAYER_A_HUMAN, Player.PLAYER_B_HUMAN:
			_handle_player_input(delta)
		_:
			_process_bot_movement(delta)

	if player == Player.PLAYER_A_HUMAN or player == Player.PLAYER_A_BOT:  # Player 1 (leftmost 25% of the screen)
		position.x = clamp(position.x, edge_margin, _screen_width_quarter)
	else:  # Player 2 (rightmost 25% of the screen)
		position.x = clamp(
			position.x,
			_screen_width_half + _screen_width_quarter,
			_display_bounds.x - edge_margin,
		)

	move_and_slide()


func _handle_player_input(delta: float) -> void:
	var input_prefix: String = (
		"player_a_" if player == Player.PLAYER_A_HUMAN else "player_b_"
	)

	if Input.is_action_pressed(input_prefix + "up"):
		velocity.y -= _current_movement_speed * delta
	if Input.is_action_pressed(input_prefix + "down"):
		velocity.y += _current_movement_speed * delta
	if Input.is_action_pressed(input_prefix + "left"):
		velocity.x -= _current_movement_speed * delta
	if Input.is_action_pressed(input_prefix + "right"):
		velocity.x += _current_movement_speed * delta


func _process_bot_movement(delta: float) -> void:
	if not _ball:
		print("No balls found to play!")
		return

	var ball_direction: Vector2 = _ball.velocity.normalized()
	var distance_to_ball: float = position.distance_to(_ball.position)
	var predicted_position: Vector2 = (
		_ball.position + ball_direction * distance_to_ball
	)

	# Add a small random offset to make the bot less perfect
	var random_offset: Vector2 = Vector2(
		randf_range(-250, 250), randf_range(-150, 150)
	)
	predicted_position += random_offset

	var direction: Vector2 = (predicted_position - position).normalized()
	velocity += direction * _current_movement_speed * delta


func sync_paddle_dimensions(new_scale: float) -> void:
	paddle_visual.scale = Vector2(new_scale, new_scale)
	paddle_visual.rotation_degrees = 90

	var texture_dimensions: Vector2 = paddle_visual.texture.get_size()
	var scaled_size: Vector2 = texture_dimensions * new_scale
	paddle_hitbox.shape.size = Vector2(scaled_size.y, scaled_size.x)


func prepare_paddle_for_play() -> void:
	_current_movement_speed = initial_paddle_velocity

	sync_paddle_dimensions(initial_paddle_scale)

	shrink_timer.stop()
	shrink_timer.wait_time = shrink_delay
	shrink_timer.start()


func get_player_control_type() -> String:
	var player_type: String = Player.keys()[player]
	return player_type.split("_")[-1].capitalize()


func _adjust_screen_partition_markers(new_size: Vector2) -> void:
	_display_bounds = new_size
	_screen_width_half = _display_bounds.x * 0.5
	_screen_width_quarter = _display_bounds.x * 0.25


func _on_ball_paddle_collision(paddle: Paddle) -> void:
	paddle_hit_sound.play()


func _on_shrink_timer_timeout() -> void:
	var new_height_scale: float = paddle_visual.scale.y * scale_reduction_rate
	if new_height_scale > minimum_scale:
		_current_movement_speed *= velocity_boost_rate

		sync_paddle_dimensions(new_height_scale)

		shrink_timer.start()
	else:
		sync_paddle_dimensions(minimum_scale)
