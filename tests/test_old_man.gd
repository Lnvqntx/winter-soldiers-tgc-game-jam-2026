extends SceneTree

func _init() -> void:
	call_deferred("_run_old_man_test")

func _run_old_man_test() -> void:
	print("--- Running Old Man Dialogue & Village Verification ---")
	var main_scene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("FAILED: Cannot load res://scenes/main.tscn")
		quit(1)
		return
	
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	
	await process_frame
	await process_frame
	
	# Verify Village elements
	var required_nodes = [
		"House1_Blue",
		"House2_Yellow",
		"House3_Green",
		"TeaStall",
		"VillageTree",
		"Props",
		"CaveEntrance",
		"OldMan",
		"Player"
	]
	
	for node_name in required_nodes:
		var n = main_instance.get_node_or_null(node_name)
		assert(n != null, "Node %s must exist in village" % node_name)
		print("[PASS] Village node verified: ", node_name)
	
	var old_man = main_instance.get_node("OldMan")
	var player = main_instance.get_node("Player")
	
	# Verify Old Man is interactable
	assert(old_man.is_in_group("interactable"), "Old Man must be in group 'interactable'")
	print("[PASS] Old Man interact text: ", old_man.get_interact_text())
	
	# Start dialogue
	old_man.interact(player)
	assert(old_man.is_talking, "Old Man should be talking")
	assert(old_man.dialogue_panel.visible, "Dialogue panel should be visible")
	print("[PASS] Dialogue started")
	
	var expected_lines = [
		{"speaker": "OLD MAN", "text": "Beta, I need your help."},
		{"speaker": "PLAYER", "text": "What happened?"},
		{"speaker": "OLD MAN", "text": "My chicken is missing."},
		{"speaker": "PLAYER", "text": "That's it?"},
		{"speaker": "OLD MAN", "text": "No. She stole my lantern."},
		{"speaker": "PLAYER", "text": "...Your chicken stole your lantern?"},
		{"speaker": "OLD MAN", "text": "Exactly."}
	]
	
	for i in range(expected_lines.size()):
		var exp = expected_lines[i]
		assert(old_man.speaker_label.text == exp["speaker"], "Speaker mismatch at line %d: got %s" % [i, old_man.speaker_label.text])
		assert(old_man.content_label.text == exp["text"], "Text mismatch at line %d: got %s" % [i, old_man.content_label.text])
		print("  [%d] %s: \"%s\"" % [i, old_man.speaker_label.text, old_man.content_label.text])
		old_man.advance_dialogue()
	
	# Verify dialogue finished
	assert(not old_man.is_talking, "Dialogue should be ended")
	assert(not old_man.dialogue_panel.visible, "Dialogue panel should be hidden")
	assert(old_man.objective_panel.visible, "Objective panel should be visible")
	assert(old_man.objective_label.text == "Find the chicken.", "Objective must be 'Find the chicken.'")
	print("[PASS] Objective verified: ", old_man.objective_label.text)
	
	# Verify subsequent interaction
	var repeat_msg = old_man.interact(player)
	print("[PASS] Subsequent interaction message: ", repeat_msg)
	
	print("==================================================")
	print("OLD MAN & VILLAGE TESTS PASSED WITH 100% SUCCESS!")
	print("==================================================")
	quit(0)
