extends Node3D

func _ready() -> void:
	_create_collisions(self)

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
		
		if should_collide:
			node.create_trimesh_collision()
			
	for child in node.get_children():
		_create_collisions(child)

