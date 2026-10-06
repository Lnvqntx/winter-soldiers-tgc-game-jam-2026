extends SceneTree

const SFXScript = preload("res://scripts/sfx.gd")
const GameStateScript = preload("res://scripts/game_state.gd")

func _init() -> void:
	call_deferred("_run_verification")

func _run_verification() -> void:
	print("\n==================================================")
	print("--- Running Verification for Visual Glitch & Cave Entry ---")
	print("==================================================")
	
	var gs = GameStateScript.new()
	gs.name = "GameState"
	root.add_child(gs)
	var sfx = SFXScript.new()
	sfx.name = "SFX"
	root.add_child(sfx)
	await process_frame
	
	var main_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame
	
	# 1. Verification of Village Visuals & Pruned Intrusions
	print("\n--- 1. Verifying Village Glitch Fixes ---")
	var forest_scene = main_scene.find_child("Tropical_Forest_Panorama_Scene", true, false)
	assert(forest_scene != null, "Forest scene must exist")
	
	var node4 = forest_scene.find_child("Node4", true, false)
	assert(node4 == null, "Intruding Node4 duplicate buildings must be removed")
	print("[PASS] Node4 duplicate monolith buildings removed from village.")
	
	var base_mesh: MeshInstance3D = forest_scene.find_child("Mesh", false, false)
	assert(base_mesh != null, "Forest base mesh must exist")
	print("base_mesh local transform: ", base_mesh.transform)
	print("base_mesh global transform: ", base_mesh.global_transform)
	print("base_mesh mesh aabb: ", base_mesh.mesh.get_aabb())
	var gaabb = base_mesh.global_transform * base_mesh.mesh.get_aabb()
	print("Forest terrain gaabb: ", gaabb)
	assert(gaabb.position.z + gaabb.size.z <= -37.0, "Forest terrain must not extend into village (Z > -38)")
	print("[PASS] Forest terrain properly clipped before village boundary; Z-fighting eliminated.")
	
	# Verify Mesh139 collision is disabled
	var mesh139: MeshInstance3D = forest_scene.find_child("Mesh139", true, false)
	assert(mesh139 != null, "Mesh139 must exist")
	var has_col = false
	for c in mesh139.get_children():
		if c is StaticBody3D:
			has_col = true
	assert(not has_col, "Mesh139 must not have trimesh collision blocking cave entrance")
	print("[PASS] Mesh139 vertical blocking collision removed.")

	# 2. Verification of Cave Entrance Ramp & Smooth Walking
	print("\n--- 2. Verifying Cave Entry & Exit Walkability ---")
	var player = main_scene.get_node("Player")
	player.global_position = Vector3(3.0, 0.1, -84.0)
	player.cam_pivot.rotation.y = deg_to_rad(90.0) # Look into cave (-X)
	
	for i in range(5):
		await physics_frame
		
	print("Starting walk into cave from: ", player.global_position)
	Input.action_press("move_forward")
	
	var entered = false
	for i in range(400):
		await physics_frame
		if i % 25 == 0:
			print("Frame ", i, " pos: ", player.global_position)
		if player.global_position.x <= -16.0:
			entered = true
			print("[PASS] Successfully entered cave! Pos: ", player.global_position, " at frame: ", i)
			break
			
	Input.action_release("move_forward")
	assert(entered, "Player must be able to walk completely inside the cave")
	
	# Verify player can interact with Cave Note
	var cave_note = main_scene.find_child("CaveNote", true, false)
	assert(cave_note != null, "Cave Note must exist")
	var dist_to_note = player.global_position.distance_to(cave_note.global_position)
	print("Distance to cave note: ", dist_to_note)
	assert(dist_to_note < 3.0, "Player should be in close proximity to Cave Note")
	print("[PASS] Player reached Cave Note area.")
	
	# 3. Walk back OUT of the cave
	print("\n--- 3. Verifying Walk Back OUT of Cave ---")
	player.cam_pivot.rotation.y = deg_to_rad(-90.0) # Look toward outside (+X)
	Input.action_press("move_forward")
	
	var exited = false
	for i in range(400):
		await physics_frame
		if player.global_position.x >= 2.0:
			exited = true
			print("[PASS] Successfully walked out of cave! Pos: ", player.global_position, " at frame: ", i)
			break
			
	Input.action_release("move_forward")
	assert(exited, "Player must be able to walk completely out of the cave")

	print("\n==================================================")
	print("★ ALL VISUAL GLITCH & CAVE ENTRY FIXES VERIFIED 100%! ★")
	print("==================================================")
	
	main_scene.queue_free()
	quit(0)
