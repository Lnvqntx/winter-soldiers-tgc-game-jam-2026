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

# Hardcoded conversation sequence requested
var conversation: Array = [
	{"speaker": "OLD MAN", "text": "Beta, I need your help."},
	{"speaker": "PLAYER", "text": "What happened?"},
	{"speaker": "OLD MAN", "text": "My chicken is missing."},
	{"speaker": "PLAYER", "text": "That's it?"},
	{"speaker": "OLD MAN", "text": "No. She stole my lantern."},
	{"speaker": "PLAYER", "text": "...Your chicken stole your lantern?"},
	{"speaker": "OLD MAN", "text": "Exactly."}
]

var current_line_idx: int = -1
var is_talking: bool = false
var has_completed_dialogue: bool = false
var current_player: Node = null

func _ready() -> void:
	add_to_group("interactable")
	if dialogue_panel:
		dialogue_panel.visible = false
	if objective_panel:
		objective_panel.visible = false

func _process(_delta: float) -> void:
	# Subtle idle breathing animation
	if visual_root:
		var time = Time.get_ticks_msec() * 0.002
		visual_root.position.y = sin(time) * 0.02

func get_interact_text() -> String:
	if not has_completed_dialogue:
		return "Talk to Old Man"
	return "Talk to Old Man"

func interact(player: Node) -> String:
	current_player = player
	if not is_talking:
		if not has_completed_dialogue:
			start_dialogue()
			return ""
		else:
			return "Old Man: 'Go on beta, find that lantern-stealing chicken!'"
	else:
		advance_dialogue()
		return ""

func _unhandled_input(event: InputEvent) -> void:
	if not is_talking:
		return
	
	# Advance dialogue on E, Space, or Left Mouse Click
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
	is_talking = true
	current_line_idx = 0
	if dialogue_panel:
		dialogue_panel.visible = true
	_display_current_line()

func advance_dialogue() -> void:
	current_line_idx += 1
	if current_line_idx < conversation.size():
		_display_current_line()
	else:
		end_dialogue()

func _display_current_line() -> void:
	if current_line_idx < 0 or current_line_idx >= conversation.size():
		return
		
	var item = conversation[current_line_idx]
	if speaker_label:
		speaker_label.text = item["speaker"]
		if item["speaker"] == "OLD MAN":
			speaker_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25)) # Marigold/Orange
		else:
			speaker_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0)) # Cyan
	
	if content_label:
		content_label.text = item["text"]
	
	if prompt_label:
		prompt_label.text = "[Press E or Space to continue...]"

func end_dialogue() -> void:
	is_talking = false
	has_completed_dialogue = true
	
	if dialogue_panel:
		dialogue_panel.visible = false
	
	# Show requested objective
	if objective_panel and objective_label:
		objective_label.text = "Find the chicken."
		objective_panel.visible = true
	
	dialogue_finished.emit()
	if current_player and current_player.has_method("show_status_message"):
		current_player.show_status_message("New Objective: Find the chicken.", 4.0)
