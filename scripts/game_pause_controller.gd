extends Node2D

@onready var pause_menu_layout: VBoxContainer = $PauseMenuLayout

var game_ended: bool = false


func _ready() -> void:
	pause_menu_layout.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if game_ended or not event.is_action_pressed("toggle_pause"):
		return

	var paused_state: bool = not get_tree().is_paused()
	get_tree().paused = paused_state
	pause_menu_layout.visible = paused_state


func set_game_ended(ended: bool) -> void:
	game_ended = ended
	if game_ended:
		pause_menu_layout.visible = false
