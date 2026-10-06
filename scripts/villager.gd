extends CharacterBody3D

signal dialogue_finished

@onready var dialogue_layer: CanvasLayer = $DialogueUI
@onready var dialogue_panel: PanelContainer = $DialogueUI/DialoguePanel
@onready var speaker_label: Label = $DialogueUI/DialoguePanel/MarginContainer/VBoxContainer/SpeakerLabel
@onready var content_label: Label = $DialogueUI/DialoguePanel/MarginContainer/VBoxContainer/ContentLabel
@onready var prompt_label: Label = $DialogueUI/DialoguePanel/MarginContainer/VBoxContainer/PromptLabel
@onready var visual_root: Node3D = $VisualRoot

# 1. Before talking to Old Man (directs player to Old Man FIRST)
var conv_before_old_man: Array = [
	{"speaker": "VILLAGER", "text": "Arre bhai! Pehle chacha se milo."},
	{"speaker": "PLAYER", "text": "Who?"},
	{"speaker": "VILLAGER", "text": "Under the big Banyan tree, sitting on the charpai! He looks super stressed."},
	{"speaker": "PLAYER", "text": "Okay, let me go talk to him first."}
]

# 2. After Old Man gives quest (directs player to chicken chase SECOND)
var conv_chicken_quest: Array = [
	{"speaker": "PLAYER", "text": "Bhai, have you seen the old man's chicken?"},
	{"speaker": "VILLAGER", "text": "Chicken? Haan bhai! Abhi abhi market stalls ke peeche daudi!"},
	{"speaker": "PLAYER", "text": "Which way?!"},
	{"speaker": "VILLAGER", "text": "Towards the bazaar stalls! Go quick, catch her before she runs into the forest!"}
]

# 3. After finding the lantern from the chicken
var conv_lantern_found: Array = [
	{"speaker": "VILLAGER", "text": "Arre wah! You got her trail? Go tell the old man quick!"}
]

# 4. While on Cave quest
var conv_cave_quest: Array = [
	{"speaker": "VILLAGER", "text": "Cave? Forest ke andar? Careful, bhai... it gets dark in there!"}
]

# 5. When player returns from cave (Old man missing)
var conv_old_man_missing: Array = [
	{"speaker": "PLAYER", "text": "Excuse me, have you seen the old man?"},
	{"speaker": "VILLAGER", "text": "Old man?"},
	{"speaker": "PLAYER", "text": "Yeah. He was standing right here under the banyan tree."},
	{"speaker": "VILLAGER", "text": "Kaunsa old man?"},
	{"speaker": "PLAYER", "text": "The one who lost his chicken!"},
	{"speaker": "VILLAGER", "text": "Bhai, there was nobody here. Just that table and a shiny coin..."},
	{"speaker": "PLAYER", "text": "...Wait, what?!"}
]

var active_conversation: Array = []
var current_line_idx: int = -1
var is_talking: bool = false
var current_player: Node = null
var default_panel_y: float = 0.0

func _ready() -> void:
	add_to_group("interactable")
	if dialogue_panel:
		dialogue_panel.visible = false

func _process(_delta: float) -> void:
	if visual_root and visual_root.visible:
		var time = Time.get_ticks_msec() * 0.002
		visual_root.position.y = sin(time + 1.0) * 0.015

func get_interact_text() -> String:
	return "Talk to Villager"

func interact(player: Node) -> String:
	current_player = player
	
	if not is_talking:
		if GameState.current_state == GameState.State.START:
			start_conversation(conv_before_old_man)
		elif GameState.current_state == GameState.State.CHICKEN_QUEST:
			start_conversation(conv_chicken_quest)
		elif GameState.current_state == GameState.State.LANTERN_FOUND:
			start_conversation(conv_lantern_found)
		elif GameState.current_state == GameState.State.CAVE_QUEST:
			start_conversation(conv_cave_quest)
		elif GameState.current_state >= GameState.State.CAVE_NOTE_FOUND:
			start_conversation(conv_old_man_missing)
		else:
			start_conversation(conv_before_old_man)
		return ""
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

func start_conversation(conv: Array) -> void:
	SFX.play_interact()
	active_conversation = conv
	is_talking = true
	current_line_idx = 0
	
	if current_player and "can_move" in current_player:
		current_player.can_move = false
		
	if dialogue_panel:
		dialogue_panel.visible = true
		dialogue_panel.modulate.a = 0.0
		dialogue_panel.pivot_offset = Vector2(240, 50)
		dialogue_panel.scale = Vector2(0.96, 0.96)
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(dialogue_panel, "modulate:a", 1.0, 0.18)
		tween.tween_property(dialogue_panel, "scale", Vector2.ONE, 0.18)
		
	_display_current_line()

func advance_dialogue() -> void:
	SFX.play_ui_click()
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
		var sb = speaker_label.get_theme_stylebox("normal")
		if sb is StyleBoxFlat:
			sb = sb.duplicate()
			if item["speaker"] == "VILLAGER":
				speaker_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
				sb.bg_color = Color(0.18, 0.62, 0.44, 1) # Emerald badge
			else:
				speaker_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
				sb.bg_color = Color(0.18, 0.52, 0.82, 1) # Hero Blue badge
			speaker_label.add_theme_stylebox_override("normal", sb)
	
	if content_label:
		content_label.text = item["text"]
		content_label.modulate.a = 0.35
		var text_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		text_tween.tween_property(content_label, "modulate:a", 1.0, 0.12)
	
	if prompt_label:
		prompt_label.text = "[ E / Space / Click ] Continue ▸"

func end_dialogue() -> void:
	is_talking = false
	if dialogue_panel:
		dialogue_panel.visible = false
		
	if current_player and "can_move" in current_player:
		current_player.can_move = true
	
	dialogue_finished.emit()
