extends SceneTree

func _init() -> void:
	call_deferred("_run_controls_test")

func _run_controls_test() -> void:
	print("--- Running Comprehensive Player Controls Verification ---")
	var main_scene = load("res://scenes/main.tscn")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	
	await process_frame
	await process_frame
	
	var player = main_instance.get_node("Player")
	
	# Wait for physics settling
	for i in range(5):
		await physics_frame
	print("Settled on floor: ", player.is_on_floor())
	
	# 1. Forward Movement Test using action
	var initial_z = player.global_position.z
	Input.action_press("move_forward")
	for i in range(15):
		await physics_frame
	Input.action_release("move_forward")
	
	print("Initial Z: %f, Current Z: %f" % [initial_z, player.global_position.z])
	assert(player.global_position.z < initial_z, "Player moved forward (-Z)")
	print("[PASS] Move Forward verified")
	
	# 2. Jump Test
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	
	# Allow upward motion
	for i in range(3):
		await physics_frame
	
	print("Player position Y after jumping: ", player.global_position.y)
	assert(player.global_position.y > 0.05, "Player should be airborne after jumping")
	print("[PASS] Jump verified")
	
	# 3. Mouse Look Test
	var initial_rot_y = player.cam_pivot.rotation.y
	var mouse_event = InputEventMouseMotion.new()
	mouse_event.relative = Vector2(80, 40)
	player._unhandled_input(mouse_event)
	print("CamPivot rotation Y: %f -> %f" % [initial_rot_y, player.cam_pivot.rotation.y])
	assert(abs(player.cam_pivot.rotation.y - initial_rot_y) > 0.001, "Camera rotated with mouse")
	print("[PASS] Mouse Camera Look verified")
	
	# 4. Proximity / Interaction Test with Old Man in Village
	var old_man = main_instance.get_node("OldMan")
	player.global_position = Vector3(3.8, 0.1, 2.4)
	for i in range(5):
		await physics_frame
	
	Input.action_press("interact")
	await physics_frame
	Input.action_release("interact")
	await physics_frame
	
	print("Old Man talking: ", old_man.is_talking)
	assert(old_man.is_talking, "Interacting with Old Man should start dialogue")
	print("[PASS] Interaction (E) verified with Old Man")
	
	print("========================================")
	print("ALL PLAYER TESTS PASSED WITH 100% SUCCESS!")
	print("========================================")
	quit(0)
