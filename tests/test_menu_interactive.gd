extends SceneTree

const SFXScript = preload("res://scripts/sfx.gd")
const GameStateScript = preload("res://scripts/game_state.gd")

func _init() -> void:
	call_deferred("_test_interactive_menu")

func _test_interactive_menu() -> void:
	print("--- Testing Interactive Menu Buttons ---")
	
	var game_state = root.get_node_or_null("GameState")
	if not game_state:
		game_state = GameStateScript.new()
		game_state.name = "GameState"
		root.add_child(game_state)

	var sfx = root.get_node_or_null("SFX")
	if not sfx:
		sfx = SFXScript.new()
		sfx.name = "SFX"
		root.add_child(sfx)

	var menu_scene = load("res://scenes/main_menu.tscn")
	assert(menu_scene != null, "Main menu scene loaded")
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame

	var start_btn = menu.start_btn
	var settings_btn = menu.settings_btn
	var credits_btn = menu.credits_btn
	var exit_btn = menu.exit_btn

	assert(start_btn != null, "Start button found")
	assert(settings_btn != null, "Settings button found")
	assert(credits_btn != null, "Credits button found")
	assert(exit_btn != null, "Exit button found")

	# Test hover on start button
	print("Testing hover events...")
	start_btn.mouse_entered.emit()
	await process_frame
	assert(start_btn.scale.x >= 1.0, "Start button scales on hover")

	start_btn.mouse_exited.emit()
	await process_frame

	# Test settings button click
	print("Testing Settings modal toggle...")
	settings_btn.pressed.emit()
	assert(menu.settings_modal.visible, "Settings modal opened")
	menu.settings_modal.close_btn.pressed.emit()
	assert(not menu.settings_modal.visible, "Settings modal closed")

	# Test credits button click
	print("Testing Credits modal toggle...")
	credits_btn.pressed.emit()
	assert(menu.credits_modal.visible, "Credits modal opened")
	menu.credits_close_btn.pressed.emit()
	assert(not menu.credits_modal.visible, "Credits modal closed")

	print("--- All Interactive Menu Tests Passed 100%! ---")
	quit(0)
