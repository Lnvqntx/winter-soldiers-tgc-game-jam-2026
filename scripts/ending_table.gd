extends StaticBody3D

@onready var visual_root: Node3D = $VisualRoot
@onready var money_mesh: MeshInstance3D = $VisualRoot/MoneyMesh
@onready var note_mesh: MeshInstance3D = $VisualRoot/NoteMesh
@onready var shimmer_light: OmniLight3D = $VisualRoot/ShimmerLight
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var joke_panel: PanelContainer = $CanvasLayer/JokePanel
@onready var joke_label: Label = $CanvasLayer/JokePanel/MarginContainer/VBoxContainer/JokeLabel
@onready var victory_panel: PanelContainer = $CanvasLayer/VictoryPanel
@onready var play_again_btn: Button = $CanvasLayer/VictoryPanel/MarginContainer/VBoxContainer/PlayAgainButton
@onready var main_menu_btn: Button = $CanvasLayer/VictoryPanel/MarginContainer/VBoxContainer/MainMenuButton

var is_active: bool = false
var has_interacted: bool = false
var is_sequence_playing: bool = false
var current_player: Node = null

func _ready() -> void:
	add_to_group("interactable")
	if joke_panel:
		joke_panel.visible = false
	if victory_panel:
		victory_panel.visible = false
	if play_again_btn:
		play_again_btn.pressed.connect(_on_play_again_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

	# Initial hidden state until cave note is read
	set_active(false)
	
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_signal("state_changed"):
		gs.state_changed.connect(_on_state_changed)
		if gs.current_state >= GameState.State.CAVE_NOTE_FOUND:
			set_active(true)

func _on_state_changed(new_state: int) -> void:
	if new_state == GameState.State.CAVE_NOTE_FOUND:
		set_active(true)

func set_active(active: bool) -> void:
	is_active = active
	visible = active
	if active:
		collision_layer = 1
		add_to_group("interactable")
	else:
		collision_layer = 0
		remove_from_group("interactable")

func _process(_delta: float) -> void:
	if not is_active or has_interacted:
		return
	
	# Shimmering golden light
	if shimmer_light:
		shimmer_light.light_energy = 1.8 + sin(Time.get_ticks_msec() * 0.008) * 0.5
	
	# Floating money / note sparkle
	if money_mesh:
		money_mesh.position.y = 0.72 + sin(Time.get_ticks_msec() * 0.004) * 0.015

func get_interact_text() -> String:
	if not is_active:
		return ""
	if not has_interacted:
		return "Pick Up ₹5 Coin"
	return ""

func interact(player: Node) -> String:
	if not is_active or has_interacted or is_sequence_playing:
		return ""
	
	current_player = player
	_start_ending_sequence()
	return ""

func _start_ending_sequence() -> void:
	is_sequence_playing = true
	has_interacted = true
	
	# Lock player movement
	if current_player:
		if "can_move" in current_player:
			current_player.can_move = false
		if "move_speed" in current_player:
			current_player.move_speed = 0.0
		# Camera zoom toward table
		if current_player.has_node("CamPivot/SpringArm3D"):
			var spring = current_player.get_node("CamPivot/SpringArm3D")
			var tween = create_tween()
			tween.tween_property(spring, "spring_length", 2.2, 0.8)

	SFX.play_dramatic()
	
	# If in headless test, complete immediately
	if DisplayServer.get_name() == "headless":
		if joke_panel:
			joke_panel.visible = true
		if victory_panel:
			victory_panel.visible = true
		GameState.set_state(GameState.State.GAME_OVER)
		return

	# Player: "₹5?"
	if current_player and current_player.has_method("show_monologue"):
		current_player.show_monologue("PLAYER: \"₹5?\"", 1.6)

	await get_tree().create_timer(1.8).timeout

	# Player: "That's my payment?"
	if current_player and current_player.has_method("show_monologue"):
		current_player.show_monologue("PLAYER: \"That's my payment?\"", 1.8)

	await get_tree().create_timer(1.8).timeout

	# Reveal the joke note
	if joke_panel:
		joke_panel.visible = true
	
	SFX.play_ending()
	GameState.set_state(GameState.State.GAME_OVER)
	
	await get_tree().create_timer(1.8).timeout

	# Player: "At least give me ₹10, bro."
	if current_player and current_player.has_method("show_monologue"):
		current_player.show_monologue("PLAYER: \"At least give me ₹10, bro.\"", 2.2)

	await get_tree().create_timer(2.4).timeout

	# Final chicken sound: "BAWK!"
	SFX.play_chicken()

	await get_tree().create_timer(0.6).timeout

	if victory_panel:
		victory_panel.visible = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_play_again_pressed() -> void:
	SFX.play_ui_click()
	GameState.reset()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	SFX.play_ui_click()
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
