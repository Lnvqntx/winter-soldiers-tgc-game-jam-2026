extends CharacterBody3D

signal dialogue_finished

@onready var dialogue_layer: CanvasLayer = $DialogueUI
@onready var dialogue_panel: PanelContainer = $DialogueUI/DialoguePanel
@onready var speaker_label: Label = $DialogueUI/DialoguePanel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var content_label: Label = $DialogueUI/DialoguePanel/MarginContainer/VBoxContainer/ContentLabel
@onready var prompt_label: Label = $DialogueUI/DialoguePanel/MarginContainer/VBoxContainer/PromptLabel
@onready var objective_panel: PanelContainer = $DialogueUI/ObjectivePanel
@onready var objective_label: Label = $DialogueUI/ObjectivePanel/MarginContainer/HBoxContainer/ObjectiveText
@onready var visual_root: Node3D = $VisualRoot

# Conversation 1: Chicken missing
var conv_initial: Array = [
	{"speaker": "OLD MAN", "text": "Beta, I need your help."},
	{"speaker": "PLAYER", "text": "What happened?"},
	{"speaker": "OLD MAN", "text": "My chicken is missing."},
	{"speaker": "PLAYER", "text": "That's it?"},
	{"speaker": "OLD MAN", "text": "No. She stole my lantern."},
	{"speaker": "PLAYER", "text": "...Your chicken stole your lantern?"},
	{"speaker": "OLD MAN", "text": "Exactly."}
]

# Conversation 2: Lantern returned -> Go to cave
var conv_lantern_returned: Array = [
	{"speaker": "OLD MAN", "text": "Ah. You found it."},
	{"speaker": "PLAYER", "text": "Your chicken stole it."},
	{"speaker": "OLD MAN", "text": "Forget that."},
	{"speaker": "PLAYER", "text": "What now?"},
	{"speaker": "OLD MAN", "text": "Go to the cave."},
	{"speaker": "PLAYER", "text": "Why?"},
	{"speaker": "OLD MAN", "text": "You'll understand."}
]

var active_conversation: Array = []
var conversation: Array = [] # Kept for backward compatibility with tests
var current_line_idx: int = -1
var is_talking: bool = false
var has_completed_dialogue: bool = false
var has_completed_cave_dialogue: bool = false
var current_player: Node = null

func _ready() -> void:
	add_to_group("interactable")
	conversation = conv_initial
	if dialogue_panel:
		dialogue_panel.visible = false
	if objective_panel:
		objective_panel.visible = false

	# Connect to GameState signals
	if Engine.has_singleton("GameState") or has_node("/root/GameState"):
		GameState.objective_updated.connect(_on_objective_updated)
		GameState.state_changed.connect(_on_state_changed)

func _on_objective_updated(text: String) -> void:
	if objective_label:
		objective_label.text = text
	if objective_panel:
		objective_panel.visible = true

func _on_state_changed(new_state: GameState.State) -> void:
	if new_state == GameState.State.CAVE_NOTE_FOUND or new_state == GameState.State.GAME_OVER:
		# Old Man disappears!
		hide_old_man()

func hide_old_man() -> void:
	if visual_root:
		visual_root.visible = false
	collision_layer = 0
	remove_from_group("interactable")

func _process(_delta: float) -> void:
	if visual_root and visual_root.visible:
		var time = Time.get_ticks_msec() * 0.002
		visual_root.position.y = sin(time) * 0.02

func get_interact_text() -> String:
	if not visual_root or not visual_root.visible:
		return ""
	return "Talk to Old Man"

func interact(player: Node) -> String:
	current_player = player
	
	if not is_talking:
		if GameState.current_state == GameState.State.START:
			start_conversation(conv_initial)
			return ""
		elif GameState.current_state == GameState.State.CHICKEN_QUEST:
			return "Old Man: 'Go on beta, find that lantern-stealing chicken!'"
		elif GameState.current_state == GameState.State.LANTERN_FOUND:
			start_conversation(conv_lantern_returned)
			return ""
		elif GameState.current_state == GameState.State.CAVE_QUEST:
			return "Old Man: 'What are you waiting for? Go to the cave!'"
		else:
			return "Old Man: 'Go on beta, find that lantern-stealing chicken!'"
	else:
		advance_dialogue()
		return ""

func _unhandled_input(event: InputEvent) -> void:
	if not is_talking:
		return
	
	var is_advancing = false
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		is_advancing = true
	elif event is InputEventKey and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER) and event.pressed:
		is_advancing = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_advancing = true

	if is_advancing:
		advance_dialogue()
		get_viewport().set_input_as_handled()

func start_dialogue() -> void:
	# Fallback / backward compat
	start_conversation(conv_initial)

func start_conversation(conv: Array) -> void:
	SFX.play_interact()
	active_conversation = conv
	conversation = conv # sync for tests
	is_talking = true
	current_line_idx = 0
	if dialogue_panel:
		dialogue_panel.visible = true
	_display_current_line()

func advance_dialogue() -> void:
	current_line_idx += 1
	if current_line_idx < active_conversation.size():
		_display_current_line()
	else:
		end_dialogue()

func _display_current_line() -> void:
	if current_line_idx < 0 or current_line_idx >= active_conversation.size():
		return
		
	var item = active_conversation[current_line_idx]
	if speaker_label:
		speaker_label.text = item["speaker"]
		if item["speaker"] == "OLD MAN":
			speaker_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
		else:
			speaker_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	
	if content_label:
		content_label.text = item["text"]
	
	if prompt_label:
		prompt_label.text = "[Press E or Space to continue...]"

func end_dialogue() -> void:
	is_talking = false
	if dialogue_panel:
		dialogue_panel.visible = false
	
	if active_conversation == conv_initial:
		has_completed_dialogue = true
		GameState.set_state(GameState.State.CHICKEN_QUEST)
		if objective_panel and objective_label:
			objective_label.text = "Find the chicken."
			objective_panel.visible = true
		if current_player and current_player.has_method("show_status_message"):
			current_player.show_status_message("New Objective: Find the chicken.", 4.0)
	elif active_conversation == conv_lantern_returned:
		has_completed_cave_dialogue = true
		GameState.set_state(GameState.State.CAVE_QUEST)
		if objective_panel and objective_label:
			objective_label.text = "Go to the cave."
			objective_panel.visible = true
		if current_player and current_player.has_method("show_status_message"):
			current_player.show_status_message("New Objective: Go to the cave.", 4.0)
	
	dialogue_finished.emit()
