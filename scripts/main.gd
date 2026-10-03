extends Node3D

@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var player: CharacterBody3D = $Player

var is_in_cave: bool = false

func _ready() -> void:
	# Ensure village daytime music starts playing
	SFX.play_music("village", 1.2)

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Dynamically transition between sunny village music and mysterious cave ambient drone
	var player_z = player.global_position.z
	if player_z < -22.0 and not is_in_cave:
		is_in_cave = true
		SFX.play_music("cave", 1.5)
	elif player_z >= -21.0 and is_in_cave:
		is_in_cave = false
		SFX.play_music("village", 1.5)
