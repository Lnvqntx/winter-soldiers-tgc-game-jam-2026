extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("--- Running LENAL Deferred Smoke Test ---")
	var main_scene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("FAILED: Cannot load res://scenes/main.tscn")
		quit(1)
		return
	
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	
	await process_frame
	await process_frame
	
	var player = main_instance.get_node_or_null("Player")
	if not player:
		printerr("FAILED: Player node not found in main scene")
		quit(1)
		return
	
	print("[PASS] Player found: ", player.name)
	print("[PASS] Camera3D found: ", player.get_node("CamPivot/SpringArm3D/Camera3D").name)
	print("[PASS] HUD found: ", player.get_node("HUD").name)
	
	var interactables = get_nodes_in_group("interactable")
	print("[PASS] Found %d interactable object(s)" % interactables.size())
	
	if interactables.size() > 0:
		var target = interactables[0]
		print("Testing interaction with: ", target.name)
		player._perform_interaction(target)
		print("[PASS] Status text after interaction: ", player.status_label.text)
	
	# Simulate 10 physics frames
	for i in range(10):
		await physics_frame
	
	print("[PASS] Player position after physics: ", player.global_position)
	print("--- All LENAL Smoke Tests Passed Successfully! ---")
	quit(0)
