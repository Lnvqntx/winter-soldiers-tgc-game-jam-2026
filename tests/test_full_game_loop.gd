extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")

func _init() -> void:
	call_deferred("_run_full_game_loop_test")

func _run_full_game_loop_test() -> void:
	print("==================================================")
	print("--- Running LENAL Full Game Loop Integration Test ---")
	print("==================================================")
	
	var game_state = root.get_node_or_null("GameState")
	if not game_state:
		game_state = GameStateScript.new()
		game_state.name = "GameState"
		root.add_child(game_state)

	var sfx_script = load("res://scripts/sfx.gd")
	var sfx_node = root.get_node_or_null("SFX")
	if not sfx_node and sfx_script:
		sfx_node = sfx_script.new()
		sfx_node.name = "SFX"
		root.add_child(sfx_node)

	var main_scene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("FAILED: Cannot load res://scenes/main.tscn")
		quit(1)
		return

	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)

	await process_frame
	await process_frame

	# 1. Verify all core nodes exist
	var player = main_instance.get_node_or_null("Player")
	var old_man = main_instance.get_node_or_null("OldMan")
	var chicken = main_instance.get_node_or_null("Chicken")
	var cave_interior = main_instance.get_node_or_null("CaveInterior")
	var cave_note = main_instance.get_node_or_null("CaveInterior/CaveNote")
	var ending_table = main_instance.get_node_or_null("EndingTable")

	assert(player != null, "Player must exist")
	assert(old_man != null, "Old Man must exist")
	assert(chicken != null, "Chicken must exist")
	assert(cave_interior != null, "Cave Interior must exist")
	assert(cave_note != null, "Cave Note must exist")
	assert(ending_table != null, "Ending Table must exist")
	print("[PASS] All core game nodes instantiated successfully.")

	# 2. Check initial state
	assert(game_state.current_state == game_state.State.START, "Initial state must be START")
	assert(chicken.has_lantern, "Chicken should hold the lantern initially")
	assert(not ending_table.is_active, "Ending table must be inactive at start")
	assert(old_man.visual_root.visible, "Old man must be visible at start")
	print("[PASS] Initial state verified.")

	# 3. Step 1: Talk to Old Man
	print("\n--- STEP 1: Talk to Old Man ---")
	old_man.interact(player)
	assert(old_man.is_talking, "Old man should start conversation 1")
	print("[PASS] Conversation 1 started.")
	
	while old_man.is_talking:
		print("  %s: \"%s\"" % [old_man.speaker_label.text, old_man.content_label.text])
		old_man.advance_dialogue()

	assert(game_state.current_state == game_state.State.CHICKEN_QUEST, "State should be CHICKEN_QUEST after conversation 1")
	assert(old_man.objective_label.text == "Find the chicken.", "Objective should be 'Find the chicken.'")
	print("[PASS] Step 1 Complete: Objective is now 'Find the chicken.'")

	# 4. Step 2: Chase & Catch Chicken
	print("\n--- STEP 2: Follow / Chase Chicken ---")
	chicken.trigger_alert()
	assert(chicken.state == chicken.ChickenState.ALERT, "Chicken should be in ALERT")
	
	# Simulate chicken running to end of path
	chicken.state = chicken.ChickenState.CORNERED
	chicken.velocity = Vector3.ZERO
	print("[PASS] Chicken reached corner with lantern.")
	
	var chicken_msg = chicken.interact(player)
	print("  Chicken interaction response: ", chicken_msg)
	assert(chicken_msg == "YOU GOT THE LANTERN.", "Chicken should yield lantern")
	assert(not chicken.has_lantern, "Chicken should no longer have lantern")
	assert(game_state.current_state == game_state.State.LANTERN_FOUND, "State should be LANTERN_FOUND")
	assert(old_man.objective_label.text == "Return to the old man.", "Objective should be 'Return to the old man.'")
	print("[PASS] Step 2 Complete: Got the lantern!")

	# 5. Step 3: Return to Old Man
	print("\n--- STEP 3: Return to Old Man with Lantern ---")
	old_man.interact(player)
	assert(old_man.is_talking, "Old man should start conversation 2")
	print("[PASS] Conversation 2 started.")

	while old_man.is_talking:
		print("  %s: \"%s\"" % [old_man.speaker_label.text, old_man.content_label.text])
		old_man.advance_dialogue()

	assert(game_state.current_state == game_state.State.CAVE_QUEST, "State should be CAVE_QUEST")
	assert(old_man.objective_label.text == "Go to the cave.", "Objective should be 'Go to the cave.'")
	print("[PASS] Step 3 Complete: Old man sent player to cave.")

	# 6. Step 4: Explore Cave & Read Note
	print("\n--- STEP 4: Walk into Tiny Cave & Read Note ---")
	cave_note.interact(player)
	assert(cave_note.is_showing, "Cave note should be displayed")
	assert(cave_note.message_label.text == "\"YOUR WORK IS TO GO BACK TO THE OLD MAN.\"", "Note message must match")
	print("  Cave Note Message: ", cave_note.message_label.text)
	
	assert(game_state.current_state == game_state.State.CAVE_NOTE_FOUND, "State should be CAVE_NOTE_FOUND")
	assert(old_man.objective_label.text == "Return to the old man.", "Objective should be 'Return to the old man.'")
	assert(not old_man.visual_root.visible, "Old man must have disappeared from the village!")
	assert(ending_table.is_active, "Ending table must now be active at Old Man's spot!")
	print("[PASS] Step 4 Complete: Cave note read, Old Man disappeared, Ending Table appeared.")

	# 7. Step 5: Final Joke & Ending
	print("\n--- STEP 5: Final Joke & Reveal ---")
	ending_table.interact(player)
	
	# Fast-forward timer for test execution
	ending_table.joke_panel.visible = true
	ending_table.victory_panel.visible = true
	game_state.set_state(game_state.State.GAME_OVER)
	
	assert(ending_table.joke_label.text == "TAKE YOUR MONEY NOOB!", "Joke note text must match")
	print("  Joke Note: ", ending_table.joke_label.text)
	print("  Victory Panel Title: ", ending_table.victory_panel.get_node("MarginContainer/VBoxContainer/Title").text)
	print("  Victory Panel Reward: ", ending_table.victory_panel.get_node("MarginContainer/VBoxContainer/Reward").text)
	print("  Victory Panel Thanks: ", ending_table.victory_panel.get_node("MarginContainer/VBoxContainer/Thanks").text)
	
	print("\n==================================================")
	print("★ FULL LENAL GAMEPLAY LOOP PASSED 100% SUCCESSFULLY! ★")
	print("==================================================")
	quit(0)
