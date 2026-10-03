extends Control

@onready var menu_ui: Control = $CanvasLayer/MenuUI
@onready var left_col: Control = $CanvasLayer/MenuUI/LeftColumn
@onready var bg_rect: TextureRect = $CanvasLayer/MenuUI/BackgroundImage

@onready var start_btn: Button = $CanvasLayer/MenuUI/LeftColumn/Buttons/StartButton
@onready var settings_btn: Button = $CanvasLayer/MenuUI/LeftColumn/Buttons/SettingsButton
@onready var credits_btn: Button = $CanvasLayer/MenuUI/LeftColumn/Buttons/CreditsButton
@onready var exit_btn: Button = $CanvasLayer/MenuUI/LeftColumn/Buttons/ExitButton

@onready var settings_modal: PanelContainer = $CanvasLayer/SettingsModal
@onready var credits_modal: PanelContainer = $CanvasLayer/CreditsModal
@onready var exit_dialog: PanelContainer = $CanvasLayer/ExitDialog
@onready var exit_close_btn: Button = $CanvasLayer/ExitDialog/MarginContainer/VBoxContainer/ExitCloseButton
@onready var credits_close_btn: Button = $CanvasLayer/CreditsModal/MarginContainer/VBoxContainer/CreditsCloseButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if SFX:
		SFX.play_music("menu")

	if settings_modal:
		settings_modal.visible = false
	if credits_modal:
		credits_modal.visible = false
	if exit_dialog:
		exit_dialog.visible = false

	# Setup buttons
	var buttons = [start_btn, settings_btn, credits_btn, exit_btn]
	for btn in buttons:
		if btn:
			_setup_button_effects(btn)

	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if credits_btn:
		credits_btn.pressed.connect(_on_credits_pressed)
	if exit_btn:
		exit_btn.pressed.connect(_on_exit_pressed)

	if exit_close_btn:
		exit_close_btn.pressed.connect(func(): exit_dialog.visible = false; if SFX: SFX.play_ui_click())
		_setup_button_effects(exit_close_btn)
	if credits_close_btn:
		credits_close_btn.pressed.connect(func(): credits_modal.visible = false; if SFX: SFX.play_ui_click())
		_setup_button_effects(credits_close_btn)

	_play_intro_animation()

func _setup_button_effects(btn: Button) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.pivot_offset = btn.size * 0.5

	btn.mouse_entered.connect(func():
		if SFX:
			SFX.play_ui_hover()
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.035, 1.035), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		var tw = btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.035, 1.035), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

func _play_intro_animation() -> void:
	if not menu_ui:
		return
	menu_ui.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(menu_ui, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_start_pressed() -> void:
	if SFX:
		SFX.play_ui_click()
		SFX.stop_music(0.5)
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed() -> void:
	if SFX:
		SFX.play_ui_click()
	if credits_modal: credits_modal.visible = false
	if exit_dialog: exit_dialog.visible = false
	if settings_modal:
		settings_modal.visible = true

func _on_credits_pressed() -> void:
	if SFX:
		SFX.play_ui_click()
	if settings_modal: settings_modal.visible = false
	if exit_dialog: exit_dialog.visible = false
	if credits_modal:
		credits_modal.visible = true

func _on_exit_pressed() -> void:
	if SFX:
		SFX.play_ui_click()
	if OS.has_feature("web"):
		if exit_dialog:
			exit_dialog.visible = true
	else:
		get_tree().quit()
