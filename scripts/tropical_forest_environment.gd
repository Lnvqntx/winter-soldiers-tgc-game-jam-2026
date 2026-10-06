extends Node3D

func _ready() -> void:
	_cleanup_village_intrusions()
	_create_collisions(self)

func _cleanup_village_intrusions() -> void:
	var scene = find_child("Tropical_Forest_Panorama_Scene", true, false)
	if not scene:
		return
	
	# 1. Remove Node4 (duplicate low-poly buildings that protrude into the village plaza)
	var node4 = scene.find_child("Node4", true, false)
	if node4:
		node4.queue_free()
	
	# 2. Remove fences, trees, and extra planes that clip into the village
	var intruding_names := [
		"Structure_Wooden_Fence",
		"Structure_Wooden_Fence2",
		"Prop_Lantern_Post",
		"Tree_Sacred_Banyan",
		"Tree_Jungle_Buttress",
		"Palm_Coconut",
		"Mesh7"
	]
	for n_name in intruding_names:
		var n = scene.find_child(n_name, true, false)
		if n:
			n.queue_free()
	
	# 3. Adjust base forest terrain so it ends cleanly at global Z = -38 (temple rear boundary)
	# and does not overlap the village terrain plane, completely eliminating Z-fighting.
	var base_mesh: MeshInstance3D = scene.find_child("Mesh", false, false)
	if base_mesh and base_mesh.mesh:
		base_mesh.position.x = 26.0
		base_mesh.scale.x = 68.0 / 120.0

func _create_collisions(node: Node) -> void:
	if node is MeshInstance3D:
		# Check ancestry: only add collision if it belongs to Cave, Bridge, or specific rocks
		var p: Node = node.get_parent()
		var should_collide := false
		while p != null and p != self:
			var pname := p.name
			if pname.begins_with("Structure_Mountain_Cave") or pname.begins_with("Structure_Wooden_Bridge") or pname.begins_with("Rock_Boulder"):
				should_collide = true
				break
			p = p.get_parent()
		
		# Skip Mesh139: it is the cave floor slab whose front face drops vertically at X = -0.4,
		# which blocks the cave mouth. Cave floor collision is cleanly handled by CaveFloor and CaveEntranceRamp.
		if node.name == "Mesh139":
			should_collide = false
		
		if should_collide:
			node.create_trimesh_collision()
			
	for child in node.get_children():
		_create_collisions(child)

