extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("==================================================")
	print("--- Running UAL1 Character & Camera System Verification ---")
	print("==================================================")
	
	var main_scene = load("res://scenes/main.tscn")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	
	await process_frame
	await process_frame
	for i in range(10):
		await physics_frame
		
	var player = main_instance.get_node("Player")
	assert(player != null, "Player must exist")
	
	# 1. Verify CharacterModel and AnimationPlayer
	var model = player.get_node_or_null("MeshRoot/CharacterModel")
	assert(model != null, "CharacterModel from UAL1_Standard.glb must be loaded under MeshRoot")
	var anim_player = player.anim_player
	assert(anim_player != null, "AnimationPlayer must exist on character")
	print("[PASS] CharacterModel & AnimationPlayer loaded successfully.")
	
	# 2. Verify Initial Idle State
	print("Initial state: ", player.current_state, " anim: ", player.current_anim)
	assert(player.current_state == player.State.IDLE, "Initial state must be IDLE")
	assert(player.current_anim == "Idle", "Initial animation must be 'Idle'")
	print("[PASS] IDLE animation state verified.")
	
	# 3. Test Camera Settings
	var cam_pivot = player.cam_pivot
	var spring_arm = player.spring_arm
	var camera = player.camera
	assert(cam_pivot != null and spring_arm != null and camera != null, "Camera rig must exist")
	assert(spring_arm.spring_length == player.camera_distance, "SpringArm length matches camera_distance")
	assert(spring_arm.collision_mask == 1, "SpringArm collision mask must include world geometry (mask 1)")
	print("SpringArm length: %f, Camera FOV: %f, Pivot Height: %f" % [spring_arm.spring_length, camera.fov, cam_pivot.position.y])
	print("[PASS] Camera & SpringArm parameters verified.")
	
	# 4. Test Walking (WASD) and Smooth Acceleration
	print("\n--- Testing Walk Locomotion & Acceleration ---")
	var start_pos = player.global_position
	Input.action_press("move_forward")
	
	# Step 1 frame: velocity should accelerate, not snap immediately to max speed
	await physics_frame
	var first_frame_speed = Vector2(player.velocity.x, player.velocity.z).length()
	print("First frame speed after forward press: %f (target: %f)" % [first_frame_speed, player.walk_speed])
	assert(first_frame_speed > 0.0 and first_frame_speed < player.walk_speed, "Velocity must accelerate smoothly, not snap instantly")
	
	# Continue walking to reach walk speed
	for i in range(20):
		await physics_frame
	var full_walk_speed = Vector2(player.velocity.x, player.velocity.z).length()
	print("Full walk speed: %f (target: %f)" % [full_walk_speed, player.walk_speed])
	assert(is_equal_approx(full_walk_speed, player.walk_speed) or abs(full_walk_speed - player.walk_speed) < 0.1, "Player reaches walk speed ~3.5")
	assert(player.current_state == player.State.WALK, "State must be WALK")
	assert(player.current_anim == "Walk", "Animation must be 'Walk'")
	print("[PASS] WALK state, speed (3.5), and smooth acceleration verified.")
	
	# 5. Test Running (Shift + WASD)
	print("\n--- Testing Run / Sprint ---")
	Input.action_press("run")
	for i in range(25):
		await physics_frame
	var run_speed_val = Vector2(player.velocity.x, player.velocity.z).length()
	print("Run speed: %f (target: %f)" % [run_speed_val, player.run_speed])
	assert(abs(run_speed_val - player.run_speed) < 0.15, "Player reaches run speed ~6.0")
	assert(player.current_state == player.State.RUN, "State must be RUN")
	assert(player.current_anim == "Jog_Fwd", "Animation must be 'Jog_Fwd'")
	print("[PASS] RUN state, speed (6.0), and Shift key verified.")
	
	# 6. Test Deceleration
	print("\n--- Testing Deceleration & Return to IDLE ---")
	Input.action_release("move_forward")
	Input.action_release("run")
	await physics_frame
	var post_release_speed = Vector2(player.velocity.x, player.velocity.z).length()
	assert(post_release_speed < run_speed_val and post_release_speed > 0.0, "Player must decelerate smoothly, not stop instantly")
	
	for i in range(20):
		await physics_frame
	var stop_speed = Vector2(player.velocity.x, player.velocity.z).length()
	print("Stopped speed: %f" % stop_speed)
	assert(stop_speed < 0.05, "Player decelerates to complete stop")
	assert(player.current_state == player.State.IDLE, "State returns to IDLE")
	assert(player.current_anim == "Idle", "Animation returns to 'Idle'")
	print("[PASS] Deceleration and transition to IDLE verified.")
	
	# 7. Test Character Rotation Facing Movement
	print("\n--- Testing Smooth Character Rotation ---")
	var initial_rot_y = player.mesh_root.rotation.y
	Input.action_press("move_right")
	await physics_frame
	var rot_after_1_frame = player.mesh_root.rotation.y
	assert(rot_after_1_frame != initial_rot_y, "Character began rotating toward movement")
	for i in range(20):
		await physics_frame
	Input.action_release("move_right")
	print("Rotation Y moving right: %f rad" % player.mesh_root.rotation.y)
	# Target for moving right (+X) is -PI/2 (-1.57 rad)
	assert(abs(player.mesh_root.rotation.y - (-PI/2)) < 0.15, "Character smoothly rotated to face right")
	print("[PASS] Smooth rotation toward movement direction verified.")
	
	# 8. Test Jump, Fall, and Land
	print("\n--- Testing Jump, Fall, and Land Animation Sequence ---")
	# Let player settle
	for i in range(10):
		await physics_frame
		
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	
	# Ascent: Jump state
	await physics_frame
	print("Ascending - Velocity Y: %f, State: %d, Anim: %s" % [player.velocity.y, player.current_state, player.current_anim])
	assert(player.current_state == player.State.JUMP, "State must be JUMP during ascent")
	assert(player.current_anim == "Jump_Start", "Animation must be 'Jump_Start'")
	print("[PASS] JUMP (Jump_Start) verified.")
	
	# Apex & Fall
	while player.velocity.y > 0.0:
		await physics_frame
	await physics_frame
	print("Falling - Velocity Y: %f, State: %d, Anim: %s" % [player.velocity.y, player.current_state, player.current_anim])
	assert(player.current_state == player.State.FALL, "State must be FALL during descent")
	assert(player.current_anim == "Jump", "Animation must be 'Jump' (airborne loop)")
	print("[PASS] FALL (Jump) verified.")
	
	# Landing
	while not player.is_on_floor():
		await physics_frame
	print("Landed - On floor: %s, State: %d, Anim: %s" % [player.is_on_floor(), player.current_state, player.current_anim])
	assert(player.current_state == player.State.LAND, "State must be LAND immediately upon touchdown")
	assert(player.current_anim == "Jump_Land", "Animation must be 'Jump_Land'")
	print("[PASS] LAND (Jump_Land) verified.")
	
	# Recovery to IDLE
	for i in range(25):
		await physics_frame
	print("Recovered - State: %d, Anim: %s" % [player.current_state, player.current_anim])
	assert(player.current_state == player.State.IDLE, "State recovers to IDLE after landing")
	assert(player.current_anim == "Idle", "Animation recovers to 'Idle'")
	print("[PASS] Recovery to IDLE verified.")
	
	# 9. Test SpringArm3D Camera Wall Collision
	print("\n--- Testing SpringArm3D Collision Against Environment Geometry ---")
	# Position player near House1_Blue and point camera arm straight into the wall
	player.global_position = Vector3(-6.5, 0.05, 4.0)
	player.cam_pivot.rotation.y = -PI / 2.0
	for i in range(10):
		await physics_frame
	var full_len = player.spring_arm.spring_length
	var hit_len = player.spring_arm.get_hit_length()
	print("SpringArm default length: %f, actual contracted length near house: %f" % [full_len, hit_len])
	assert(hit_len < full_len - 0.5, "SpringArm must contract against house wall to prevent clipping")
	assert(hit_len > 0.0, "SpringArm length is valid and positive")
	print("[PASS] SpringArm3D collision contraction against house wall verified (5.5m -> %.2fm)." % hit_len)
	
	print("\n==================================================")
	print("★ ALL UAL1 INTEGRATION VERIFICATIONS PASSED 100%! ★")
	print("==================================================")
	quit(0)
