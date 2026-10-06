extends SceneTree

const SFXScript = preload("res://scripts/sfx.gd")
const GameStateScript = preload("res://scripts/game_state.gd")

var sfx_node: Node
var game_state: Node

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("==================================================")
	print("--- Running Full Game Polish & System Verification ---")
	print("==================================================")
	
	game_state = root.get_node_or_null("GameState")
	if not game_state:
		game_state = GameStateScript.new()
		game_state.name = "GameState"
		root.add_child(game_state)

	sfx_node = root.get_node_or_null("SFX")
	if not sfx_node:
		sfx_node = SFXScript.new()
		sfx_node.name = "SFX"
		root.add_child(sfx_node)

	await process_frame
	
	# 1. Test Main Menu Scene
	print("\n--- 1. Testing Main Menu ---")
	var menu_scene = load("res://scenes/main_menu.tscn")
	assert(menu_scene != null, "Main menu scene must exist")
	var menu_inst = menu_scene.instantiate()
	root.add_child(menu_inst)
	await process_frame
	
	assert(menu_inst.get_node("CanvasLayer/MenuUI/LeftColumn/Logo") != null, "Logo exists")
	assert(menu_inst.get_node("CanvasLayer/MenuUI/LeftColumn/StoryCard") != null, "Story card exists")
	assert(menu_inst.get_node("CanvasLayer/MenuUI/LeftColumn/Buttons/StartButton") != null, "Start button exists")
	
	# Test Credits Modal
	menu_inst._on_credits_pressed()
	assert(menu_inst.credits_modal.visible, "Credits modal opens")
	var credits_text = menu_inst.get_node("CanvasLayer/CreditsModal/MarginContainer/VBoxContainer/CreditsContent").text
	assert(credits_text.contains("Winter Soldiers"), "Credits contains team name Winter Soldiers")
	assert(credits_text.contains("TGC Game Jam 2026"), "Credits contains TGC Game Jam 2026")
	assert(credits_text.contains("Quaternius"), "Credits contains Quaternius")
	assert(credits_text.contains("Universal Animation Library"), "Credits contains Universal Animation Library")
	print("[PASS] Main Menu & Credits Modal verified.")
	
	# Test Settings Modal in Menu
	menu_inst._on_settings_pressed()
	assert(menu_inst.settings_modal.visible, "Settings modal opens")
	menu_inst.settings_modal._on_master_changed(50.0)
	assert(is_equal_approx(sfx_node.master_volume, 0.5), "Master volume set to 0.5")
	menu_inst.settings_modal._on_music_changed(60.0)
	assert(is_equal_approx(sfx_node.music_volume, 0.6), "Music volume set to 0.6")
	menu_inst.settings_modal._on_sfx_changed(70.0)
	assert(is_equal_approx(sfx_node.sfx_volume, 0.7), "SFX volume set to 0.7")
	menu_inst.settings_modal._on_sens_changed(4.0)
	assert(is_equal_approx(sfx_node.mouse_sensitivity_setting, 0.004), "Sensitivity set to 0.004")
	print("[PASS] Settings Modal & Volume sliders verified.")
	
	menu_inst.queue_free()
	await process_frame
	
	# 2. Test Main Scene with Pause Menu & Dialogue Lock
	print("\n--- 2. Testing Main Scene, Pause Menu & Dialogue Lock ---")
	var main_scene = load("res://scenes/main.tscn")
	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	await process_frame
	await process_frame
	
	var player = main_inst.get_node("Player")
	var old_man = main_inst.get_node("OldMan")
	var pause_menu = main_inst.get_node("PauseMenu")
	assert(player != null, "Player exists")
	assert(old_man != null, "OldMan exists")
	assert(pause_menu != null, "PauseMenu exists")
	
	# Verify Pause Menu
	pause_menu.pause_game()
	assert(paused, "SceneTree must be paused when PauseMenu is open")
	assert(pause_menu.visible, "PauseMenu must be visible")
	pause_menu.resume_game()
	assert(not paused, "SceneTree must be unpaused after resume")
	assert(not pause_menu.visible, "PauseMenu must be hidden after resume")
	print("[PASS] Pause & Resume functionality verified.")
	
	# Test Dialogue Lock
	print("\n--- 3. Testing Dialogue Movement Lock ---")
	assert(player.can_move, "Player can move initially")
	old_man.interact(player)
	assert(old_man.is_talking, "Old Man is talking")
	assert(not player.can_move, "Player movement must be LOCKED while talking")
	print("[PASS] Player movement locked during dialogue.")
	
	# Finish dialogue
	while old_man.is_talking:
		old_man.advance_dialogue()
	assert(not old_man.is_talking, "Dialogue completed")
	assert(player.can_move, "Player movement must be RESTORED after dialogue")
	print("[PASS] Player movement unlocked after dialogue.")
	
	# Test Zone Music Transition
	print("\n--- 4. Testing Village -> Cave Music Transition ---")
	player.global_position = Vector3(-18.0, 1.0, -84.0) # Inside mountain cave
	main_inst._process(0.1)
	assert(main_inst.is_in_cave, "Should detect player inside cave")
	assert(sfx_node._current_music_track == "music_cave", "Music should switch to cave music")
	print("[PASS] Cave music transition verified.")
	
	player.global_position = Vector3(0.0, 0.1, 5.0) # Back to village
	main_inst._process(0.1)
	assert(not main_inst.is_in_cave, "Should detect player in village")
	assert(sfx_node._current_music_track == "music_village", "Music should switch to village music")
	print("[PASS] Village music transition verified.")
	
	# Test Clean Reset
	print("\n--- 5. Testing GameState Clean Reset ---")
	game_state.set_state(game_state.State.LANTERN_FOUND)
	assert(game_state.has_lantern, "Has lantern before reset")
	game_state.reset()
	assert(game_state.current_state == game_state.State.START, "State reset to START")
	assert(not game_state.has_lantern, "Lantern reset to false")
	print("[PASS] Clean GameState reset verified.")
	
	main_inst.queue_free()
	print("\n==================================================")
	print("★ ALL FEATURE & POLISH TESTS PASSED 100%! ★")
	print("==================================================")
	quit(0)
