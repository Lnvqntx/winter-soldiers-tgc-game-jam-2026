extends CharacterBody3D

signal interacted_with(target)

@export var move_speed: float = 6.0
@export var acceleration: float = 24.0
@export var friction: float = 20.0
@export var jump_velocity: float = 7.5
@export var mouse_sensitivity: float = 0.003
@export var rotation_speed: float = 12.0

@onready var cam_pivot: Node3D = $CamPivot
@onready var spring_arm: SpringArm3D = $CamPivot/SpringArm3D
@onready var camera: Camera3D = $CamPivot/SpringArm3D/Camera3D
@onready var mesh_root: Node3D = $MeshRoot
@onready var interact_ray: RayCast3D = $CamPivot/SpringArm3D/Camera3D/InteractRay
@onready var interact_prompt: Label = $HUD/InteractPrompt
@onready var status_label: Label = $HUD/StatusLabel

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var current_interactable: Node = null
var status_timer: float = 0.0
var jump_buffer: float = 0.0

func _ready() -> void:
	_ensure_input_mappings()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if interact_prompt:
		interact_prompt.visible = false
	if status_label:
		status_label.text = "LENAL Prototype - WASD: Move | Mouse: Look | Space: Jump | E: Interact"

func _ensure_input_mappings() -> void:
	var defaults = {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"interact": [KEY_E],
	}
	for action in defaults:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in defaults[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = k
			ev.keycode = k
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse lock / unlock toggle
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Click to recapture mouse
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Mouse camera rotation
	if event is InputEventMouseMotion and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless"):
		apply_look_rotation(event.relative.x, event.relative.y)

func apply_look_rotation(rel_x: float, rel_y: float) -> void:
	cam_pivot.rotate_y(-rel_x * mouse_sensitivity)
	spring_arm.rotate_x(-rel_y * mouse_sensitivity)
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-70.0), deg_to_rad(60.0))

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.2
	elif jump_buffer > 0.0:
		jump_buffer -= delta

	if jump_buffer > 0.0 and is_on_floor():
		velocity.y = jump_velocity
		jump_buffer = 0.0

	# Calculate movement direction relative to camera yaw
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := cam_pivot.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir := (forward * (-input_dir.y) + right * input_dir.x).normalized()

	# Horizontal velocity with smooth acceleration & friction
	var target_vel_x := move_dir.x * move_speed
	var target_vel_z := move_dir.z * move_speed

	var accel := acceleration if move_dir.length_squared() > 0.001 else friction
	velocity.x = move_toward(velocity.x, target_vel_x, accel * delta)
	velocity.z = move_toward(velocity.z, target_vel_z, accel * delta)

	move_and_slide()

	# Rotate player mesh to face movement direction
	if move_dir.length_squared() > 0.01:
		var target_angle := atan2(-move_dir.x, -move_dir.z)
		mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_angle, rotation_speed * delta)

	# Procedural footstep wobble for primitive placeholder
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_speed > 0.5:
		var bob_time = Time.get_ticks_msec() * 0.012
		mesh_root.position.y = abs(sin(bob_time)) * 0.08
		mesh_root.rotation.z = sin(bob_time * 0.5) * 0.04
	else:
		mesh_root.position.y = move_toward(mesh_root.position.y, 0.0, delta * 2.0)
		mesh_root.rotation.z = move_toward(mesh_root.rotation.z, 0.0, delta * 2.0)

	_update_interaction()
	_update_hud(delta)

func _update_interaction() -> void:
	current_interactable = null
	
	if interact_ray and interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider and collider.is_in_group("interactable"):
			current_interactable = collider
	
	# Proximity fallback area detection
	if not current_interactable and has_node("InteractArea"):
		var areas = $InteractArea.get_overlapping_bodies()
		for b in areas:
			if b.is_in_group("interactable"):
				current_interactable = b
				break

	if interact_prompt:
		if current_interactable:
			var obj_name = current_interactable.name
			if current_interactable.has_method("get_interact_text"):
				obj_name = current_interactable.get_interact_text()
			interact_prompt.text = "[E] " + obj_name
			interact_prompt.visible = true
		else:
			interact_prompt.visible = false

	# Handle interact action
	if Input.is_action_just_pressed("interact") and current_interactable:
		_perform_interaction(current_interactable)

func _perform_interaction(obj: Node) -> void:
	interacted_with.emit(obj)
	var response_msg := ""
	if obj.has_method("interact"):
		response_msg = str(obj.interact(self))
	else:
		response_msg = "Interacted with " + obj.name
	
	show_status_message(response_msg)

func show_status_message(msg: String, duration: float = 3.5) -> void:
	if status_label:
		status_label.text = msg
		status_timer = duration

func _update_hud(delta: float) -> void:
	if status_timer > 0.0:
		status_timer -= delta
		if status_timer <= 0.0 and status_label:
			status_label.text = "LENAL Prototype - WASD: Move | Mouse: Look | Space: Jump | E: Interact"
