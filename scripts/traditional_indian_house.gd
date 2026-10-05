extends StaticBody3D

func _ready() -> void:
	add_to_group("interactable")

func get_interact_text() -> String:
	return "Inspect Heritage House"

func interact(player: Node) -> String:
	return "Heritage House: A traditional Indian residence with hand-carved teakwood pillars and cool terracotta roof."
