extends StaticBody3D

@onready var note_mesh: MeshInstance3D = $NoteMesh
@onready var aura_light: OmniLight3D = $AuraLight
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var note_panel: PanelContainer = $CanvasLayer/NotePanel
@onready var message_label: Label = $CanvasLayer/NotePanel/MarginContainer/VBoxContainer/MessageLabel
@onready var close_label: Label = $CanvasLayer/NotePanel/MarginContainer/VBoxContainer/CloseLabel

var is_showing: bool = false
var has_been_read: bool = false
var current_player: Node = null

func _ready() -> void:
	add_to_group("interactable")
	if note_panel:
		note_panel.visible = false

func _process(_delta: float) -> void:
	# Subtle floating / pulsing glow on note
	if aura_light:
		aura_light.light_energy = 1.2 + sin(Time.get_ticks_msec() * 0.005) * 0.4
	if note_mesh:
		note_mesh.position.y = 0.55 + sin(Time.get_ticks_msec() * 0.003) * 0.02

func get_interact_text() -> String:
	return "Read Cave Note"

func interact(player: Node) -> String:
	current_player = player
	if not is_showing:
		show_note()
		return ""
	else:
		hide_note()
		return ""

func _unhandled_input(event: InputEvent) -> void:
	if not is_showing:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("jump") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		hide_note()
		get_viewport().set_input_as_handled()

func show_note() -> void:
	is_showing = true
	SFX.play_note()
	if note_panel:
		note_panel.visible = true
	
	if not has_been_read:
		has_been_read = true
		GameState.set_state(GameState.State.CAVE_NOTE_FOUND)
		if current_player and current_player.has_method("show_status_message"):
			current_player.show_status_message("New Objective: Return to the old man.", 4.0)

func hide_note() -> void:
	is_showing = false
	if note_panel:
		note_panel.visible = false
