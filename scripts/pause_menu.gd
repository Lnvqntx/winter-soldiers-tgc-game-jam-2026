extends CanvasLayer

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Backdrop/CenterContainer/PauseCard
@onready var resume_btn: Button = $Backdrop/CenterContainer/PauseCard/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $Backdrop/CenterContainer/PauseCard/MarginContainer/VBoxContainer/RestartButton
@onready var settings_btn: Button = $Backdrop/CenterContainer/PauseCard/MarginContainer/VBoxContainer/SettingsButton
@onready var menu_btn: Button = $Backdrop/CenterContainer/PauseCard/MarginContainer/VBoxContainer/MenuButton
@onready var settings_modal: PanelContainer = $Backdrop/SettingsModal

var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if settings_modal:
		settings_modal.visible = false
		settings_modal.closed.connect(_on_settings_closed)

	if resume_btn:
		resume_btn.pressed.connect(resume_game)
	if restart_btn:
		restart_btn.pressed.connect(restart_game)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		if settings_modal and settings_modal.visible:
			settings_modal.visible = false
			panel.visible = true
			get_viewport().set_input_as_handled()
			return
			
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	is_paused = true
	visible = true
	if panel:
		panel.visible = true
	if settings_modal:
		settings_modal.visible = false
		
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SFX.play_ui_click()

func resume_game() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SFX.play_ui_click()

func restart_game() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SFX.play_ui_click()
	
	# Complete clean reset
	GameState.reset()
	get_tree().reload_current_scene()

func _on_settings_pressed() -> void:
	SFX.play_ui_click()
	if panel:
		panel.visible = false
	if settings_modal:
		settings_modal.visible = true

func _on_settings_closed() -> void:
	if panel:
		panel.visible = true

func _on_main_menu_pressed() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SFX.play_ui_click()
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
