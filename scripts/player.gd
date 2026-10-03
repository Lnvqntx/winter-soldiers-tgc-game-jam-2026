extends CharacterBody3D

signal interacted_with(target)

enum State {
	IDLE,
	WALK,
	RUN,
	JUMP,
	FALL,
	LAND
}

@export_group("Movement Settings")
@export var walk_speed: float = 3.5
@export var run_speed: float = 6.0
@export var acceleration: float = 20.0
@export var deceleration: float = 24.0
@export var jump_velocity: float = 7.5
@export var rotation_speed: float = 12.0
@export var can_move: bool = true

@export_group("Camera Settings")
@export var camera_distance: float = 5.5
@export var camera_height: float = 2.4
@export var camera_fov: float = 65.0
@export var camera_look_pitch: float = -12.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -70.0
@export var max_pitch: float = 45.0

@export_group("Animation Mapping")
@export var anim_idle: String = "Idle"
@export var anim_walk: String = "Walk"
@export var anim_run: String = "Jog_Fwd"
@export var anim_jump: String = "Jump_Start"
@export var anim_fall: String = "Jump"
@export var anim_land: String = "Jump_Land"

@onready var cam_pivot: Node3D = $CamPivot
@onready var spring_arm: SpringArm3D = $CamPivot/SpringArm3D
@onready var camera: Camera3D = $CamPivot/SpringArm3D/Camera3D
@onready var mesh_root: Node3D = $MeshRoot
@onready var interact_ray: RayCast3D = $CamPivot/SpringArm3D/Camera3D/InteractRay
@onready var interact_prompt: Label = $HUD/InteractPrompt
@onready var status_label: Label = $HUD/StatusLabel

# Animation player from imported UAL1_Standard.glb
@onready var anim_player: AnimationPlayer = $MeshRoot/CharacterModel/AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var current_interactable: Node = null
var status_timer: float = 0.0
var jump_buffer: float = 0.0
var footstep_timer: float = 0.0

var current_state: State = State.IDLE
var current_anim: String = ""
var land_timer: float = 0.0
var was_on_floor: bool = true
var prev_vertical_vel: float = 0.0

func _ready() -> void:
	_ensure_input_mappings()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if interact_prompt:
		interact_prompt.visible = false
	if status_label:
		status_label.text = "LENAL — Stylized Indian Comic Adventure"
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.has_signal("objective_updated"):
		gs.objective_updated.connect(_on_objective_updated)

	# Read global mouse sensitivity if configured
	if SFX and "mouse_sensitivity_setting" in SFX:
		mouse_sensitivity = SFX.mouse_sensitivity_setting

	# Apply exported camera tuning
	if cam_pivot:
		cam_pivot.position.y = camera_height
	if spring_arm:
		spring_arm.spring_length = camera_distance
		spring_arm.rotation.x = deg_to_rad(camera_look_pitch)
	if camera:
		camera.fov = camera_fov

	# Start initial animation
	_play_anim(anim_idle, 0.0)

func _on_objective_updated(text: String) -> void:
	show_status_message("Objective: " + text, 5.0)

func _ensure_input_mappings() -> void:
	var defaults = {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"run": [KEY_SHIFT],
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
	# ESC toggles pause menu
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		var pause_menus = get_tree().get_nodes_in_group("pause_menu")
		if pause_menus.size() > 0:
			pause_menus[0].toggle_pause()
			get_viewport().set_input_as_handled()
			return
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
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# If locked by dialogue or sequence, decelerate to stop
	if not can_move:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		var falling_speed := prev_vertical_vel
		prev_vertical_vel = velocity.y
		move_and_slide()
		_update_animation_state(delta, false, false, falling_speed)
		_update_hud(delta)
		was_on_floor = is_on_floor()
		return

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.2
	elif jump_buffer > 0.0:
		jump_buffer -= delta

	if jump_buffer > 0.0 and is_on_floor():
		velocity.y = jump_velocity
		jump_buffer = 0.0
		current_state = State.JUMP
		_play_anim(anim_jump, 0.12)
		SFX.play_jump()

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
	var has_input := input_dir.length_squared() > 0.01

	var is_running := (Input.is_action_pressed("run") or Input.is_key_pressed(KEY_SHIFT)) and has_input
	var target_speed := run_speed if is_running else walk_speed
	var target_vel := move_dir * target_speed

	var accel_rate := acceleration if has_input else deceleration
	velocity.x = move_toward(velocity.x, target_vel.x, accel_rate * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, accel_rate * delta)

	var falling_speed := prev_vertical_vel
	prev_vertical_vel = velocity.y

	move_and_slide()

	# Rotate character mesh smoothly toward movement direction
	if has_input and move_dir.length_squared() > 0.01:
		var target_angle := atan2(-move_dir.x, -move_dir.z)
		mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_angle, rotation_speed * delta)

	# Animation state machine
	_update_animation_state(delta, has_input, is_running, falling_speed)

	# Footsteps audio
	_update_footsteps(delta, is_running)

	_update_interaction()
	_update_hud(delta)

	was_on_floor = is_on_floor()

func _update_animation_state(delta: float, has_input: bool, is_running: bool, falling_speed: float) -> void:
	var horiz_speed := Vector2(velocity.x, velocity.z).length()

	if is_on_floor():
		# Landing detection
		if not was_on_floor and falling_speed < -1.5:
			current_state = State.LAND
			land_timer = 0.35
			_play_anim(anim_land, 0.1)
			SFX.play_land()

		if current_state == State.LAND:
			if has_input:
				# Break out of landing into locomotion if player is actively moving
				if is_running:
					current_state = State.RUN
					_play_anim(anim_run, 0.2)
				else:
					current_state = State.WALK
					_play_anim(anim_walk, 0.2)
			else:
				land_timer -= delta
				if land_timer <= 0.0:
					current_state = State.IDLE
					_play_anim(anim_idle, 0.25)
		else:
			if horiz_speed < 0.2:
				current_state = State.IDLE
				_play_anim(anim_idle, 0.25)
			elif is_running:
				current_state = State.RUN
				_play_anim(anim_run, 0.2)
			else:
				current_state = State.WALK
				_play_anim(anim_walk, 0.2)
	else:
		# Airborne states
		if velocity.y > 0.5:
			current_state = State.JUMP
			_play_anim(anim_jump, 0.15)
		else:
			current_state = State.FALL
			_play_anim(anim_fall, 0.25)

func _play_anim(anim_name: String, blend_time: float = 0.2) -> void:
	if current_anim == anim_name:
		return
	current_anim = anim_name
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name, blend_time)

func _update_footsteps(delta: float, is_running: bool) -> void:
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horiz_speed > 0.5:
		footstep_timer += delta
		var step_interval := 0.30 if is_running else 0.42
		if footstep_timer >= step_interval:
			footstep_timer = 0.0
			SFX.play_footstep()
	else:
		footstep_timer = 0.25

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
		if not current_interactable:
			var area_nodes = $InteractArea.get_overlapping_areas()
			for a in area_nodes:
				if a.is_in_group("interactable"):
					current_interactable = a
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
			status_label.text = "LENAL — Stylized Indian Village Adventure"
