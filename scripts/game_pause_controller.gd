extends Node2D

@onready var pause_menu_layout: VBoxContainer = $PauseMenuLayout


func _ready() -> void:
	pause_menu_layout.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_pause"):
		return

	var paused_state: bool = not get_tree().is_paused()
	get_tree().paused = paused_state
	pause_menu_layout.visible = paused_state
