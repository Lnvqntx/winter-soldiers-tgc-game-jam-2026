extends PanelContainer

signal closed

@onready var master_slider: HSlider = $MarginContainer/VBoxContainer/Grid/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/VBoxContainer/Grid/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/VBoxContainer/Grid/SfxSlider
@onready var sens_slider: HSlider = $MarginContainer/VBoxContainer/Grid/SensSlider
@onready var fullscreen_check: CheckBox = $MarginContainer/VBoxContainer/Grid/FullscreenCheck
@onready var close_btn: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if master_slider:
		master_slider.value = SFX.master_volume * 100.0
		master_slider.value_changed.connect(_on_master_changed)
	if music_slider:
		music_slider.value = SFX.music_volume * 100.0
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value = SFX.sfx_volume * 100.0
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if sens_slider:
		sens_slider.value = SFX.mouse_sensitivity_setting * 1000.0
		sens_slider.value_changed.connect(_on_sens_changed)
	if fullscreen_check:
		fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

func _on_master_changed(val: float) -> void:
	SFX.set_master_volume(val / 100.0)

func _on_music_changed(val: float) -> void:
	SFX.set_music_volume(val / 100.0)

func _on_sfx_changed(val: float) -> void:
	SFX.set_sfx_volume(val / 100.0)

func _on_sens_changed(val: float) -> void:
	SFX.mouse_sensitivity_setting = val / 1000.0
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if "mouse_sensitivity" in p:
			p.mouse_sensitivity = SFX.mouse_sensitivity_setting

func _on_fullscreen_toggled(pressed: bool) -> void:
	SFX.play_ui_click()
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_close_pressed() -> void:
	SFX.play_ui_click()
	visible = false
	closed.emit()
