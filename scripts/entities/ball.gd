class_name Ball
extends CharacterBody2D

signal boundary_collision(collider: Node)
signal paddle_collision(paddle: Paddle)

@export var initial_speed: float = 300.0
@export var max_speed: float = 1400.0
@export var speed_increase_rate: float = 1.07

@export var initial_ball_diameter: float = 28.0
@export var shrunk_ball_diameter: float = 18.0
@export var shrink_delay: float = 15.0

@onready var shrink_timer: Timer = $ShrinkTimer

@onready var ball_visual: Sprite2D = $BallVisual
@onready var ball_hitbox: CollisionShape2D = $BallHitbox

var direction: Vector2
var current_speed: float


func _ready() -> void:
	sync_ball_dimensions(initial_ball_diameter)

	shrink_timer.wait_time = shrink_delay

	start_new_ball_round()


func _physics_process(delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if not collision:
		return

	velocity = velocity.bounce(collision.get_normal())

	current_speed = min(current_speed * speed_increase_rate, max_speed)
	velocity = velocity.normalized() * current_speed

	var collider: Object = collision.get_collider()
	if collider.is_in_group("Boundaries"):
		emit_signal("boundary_collision", collider)
	elif collider.is_in_group("Paddles"):
		emit_signal("paddle_collision", collider)


func sync_ball_dimensions(new_diameter: float) -> void:
	ball_hitbox.shape.radius = new_diameter / 2

	var texture_dimensions: Vector2 = ball_visual.texture.get_size()
	var scale_factor: float = (
		new_diameter / max(texture_dimensions.x, texture_dimensions.y)
	)
	ball_visual.scale = Vector2(scale_factor, scale_factor)


func start_new_ball_round() -> void:
	sync_ball_dimensions(initial_ball_diameter)

	position = get_viewport_rect().size / 2

	current_speed = initial_speed

	var random_angle: float = randf_range(-PI / 4, PI / 4)
	if randi() % 2 == 0:
		direction = Vector2.RIGHT.rotated(random_angle)
	else:
		direction = Vector2.LEFT.rotated(random_angle)
	velocity = direction * current_speed

	shrink_timer.start()


func _on_shrink_timer_timeout() -> void:
	sync_ball_dimensions(shrunk_ball_diameter)
