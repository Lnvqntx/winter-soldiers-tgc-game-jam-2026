extends StaticBody3D

@export var prompt_name: String = "Test Object"
@export var message: String = "Interacted with Test Object!"

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var default_color: Color = Color(0.9, 0.6, 0.2)
var active_color: Color = Color(0.2, 0.9, 0.4)
var is_active: bool = false

func _ready() -> void:
	add_to_group("interactable")
	_update_material()

func get_interact_text() -> String:
	return prompt_name

func interact(_player: Node) -> String:
	is_active = !is_active
	_update_material()
	
	# Small bounce effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
	
	return message + (" (Toggled ON)" if is_active else " (Toggled OFF)")

func _update_material() -> void:
	if mesh_instance:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = active_color if is_active else default_color
		mat.roughness = 0.4
		mesh_instance.material_override = mat
