extends Node3D

func _ready() -> void:
	_create_village_collisions(self)

func _create_village_collisions(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var p: Node = node.get_parent()
		var should_collide := false
		while p != null and p != self:
			var pname := p.name
			# Collide on:
			# 2_ Entrance & Boundary (gates, stone walls)
			# 3_ 4 House Variants (all houses, walls, roofs, pillars)
			# 4_ Temple Complex (temple walls, steps, sanctum)
			# 5_ Banyan Village Square (tree trunk, chabutra)
			# 6_ Village Bazaar (stalls, shop counters)
			# 7_ Village Well (stone well cylinder)
			# 8_ River & Bridge (bridge railings, river boundaries)
			# 10_ Agricultural Area (farm fences)
			# 11_ Infrastructure (light/utility poles)
			# 12_ General Village Props (carts, crates)
			if pname.begins_with("2_") or pname.begins_with("3_") or pname.begins_with("4_") \
				or pname.begins_with("5_") or pname.begins_with("6_") or pname.begins_with("7_") \
				or pname.begins_with("8_") or pname.begins_with("10_") or pname.begins_with("11_") \
				or pname.begins_with("12_"):
				
				# Filter out canopy leaves so player isn't blocked by floating leaf cards
				var n_low = node.name.to_lower()
				if not n_low.contains("leaf") and not n_low.contains("flora") and not n_low.contains("canopy"):
					should_collide = true
				break
			p = p.get_parent()
		
		if should_collide:
			node.create_trimesh_collision()
			for child in node.get_children():
				if child is StaticBody3D:
					child.collision_layer = 1
					child.collision_mask = 3
					
	for child in node.get_children():
		_create_village_collisions(child)
