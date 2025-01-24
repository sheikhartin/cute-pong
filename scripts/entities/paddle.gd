class_name Paddle
extends CharacterBody2D

@export var edge_margin: float = 25.0

@export var movement_speed: float = 2300.0
@export var slowdown_intensity: float = 6.0

enum Player {
	PLAYER_A_HUMAN,
	PLAYER_A_BOT,
	PLAYER_B_HUMAN,
	PLAYER_B_BOT,
}

@export var player: Player = Player.PLAYER_A_HUMAN
@export var custom_texture: Texture2D

@export var initial_paddle_scale: float = 0.28

@onready var paddle_visual: Sprite2D = $PaddleVisual
@onready var paddle_hitbox: CollisionShape2D = $PaddleHitbox

@onready var paddle_hit_sound: AudioStreamPlayer2D = $PaddleHitSound

var _display_bounds: Vector2
var _screen_width_half: float
var _screen_width_quarter: float


func _ready() -> void:
	if custom_texture:
		paddle_visual.texture = custom_texture

	sync_paddle_dimensions(initial_paddle_scale)

	if player == Player.PLAYER_B_HUMAN or player == Player.PLAYER_B_BOT:
		paddle_visual.flip_v = true

	_adjust_screen_partition_markers(get_viewport_rect().size)
	# get_viewport().size_changed.connect(_adjust_screen_partition_markers)

	var ball: Ball = get_tree().get_root().find_child("Ball", true, false)
	if ball:
		ball.paddle_collision.connect(_on_ball_paddle_collision)


func _physics_process(delta: float) -> void:
	velocity -= velocity * delta * slowdown_intensity

	match player:
		Player.PLAYER_A_HUMAN:
			if Input.is_action_pressed("player_a_up"):
				velocity.y -= movement_speed * delta
			if Input.is_action_pressed("player_a_down"):
				velocity.y += movement_speed * delta
			if Input.is_action_pressed("player_a_left"):
				velocity.x -= movement_speed * delta
			if Input.is_action_pressed("player_a_right"):
				velocity.x += movement_speed * delta
		Player.PLAYER_B_HUMAN:
			if Input.is_action_pressed("player_b_up"):
				velocity.y -= movement_speed * delta
			if Input.is_action_pressed("player_b_down"):
				velocity.y += movement_speed * delta
			if Input.is_action_pressed("player_b_left"):
				velocity.x -= movement_speed * delta
			if Input.is_action_pressed("player_b_right"):
				velocity.x += movement_speed * delta

	if player == Player.PLAYER_A_HUMAN or player == Player.PLAYER_A_BOT:  # Player 1 (leftmost 25% of the screen)
		position.x = clamp(position.x, edge_margin, _screen_width_quarter)
	else:  # Player 2 (rightmost 25% of the screen)
		position.x = clamp(
			position.x,
			_screen_width_half + _screen_width_quarter,
			_display_bounds.x - edge_margin,
		)

	move_and_slide()


func sync_paddle_dimensions(new_scale: float) -> void:
	paddle_visual.scale = Vector2(new_scale, new_scale)
	paddle_visual.rotation_degrees = 90

	var texture_dimensions: Vector2 = paddle_visual.texture.get_size()
	var scaled_size: Vector2 = texture_dimensions * new_scale
	paddle_hitbox.shape.size = Vector2(scaled_size.y, scaled_size.x)


func get_player_control_type() -> String:
	var player_type: String = Player.keys()[player]
	return player_type.split("_")[-1]


func _adjust_screen_partition_markers(new_size: Vector2) -> void:
	_display_bounds = new_size
	_screen_width_half = _display_bounds.x * 0.5
	_screen_width_quarter = _display_bounds.x * 0.25


func _on_ball_paddle_collision(paddle: Paddle) -> void:
	paddle_hit_sound.play()
