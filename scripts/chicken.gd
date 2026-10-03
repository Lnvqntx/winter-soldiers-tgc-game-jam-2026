extends CharacterBody3D

signal lantern_taken

enum ChickenState {
	IDLE,
	ALERT,
	RUNNING,
	CORNERED,
	CAUGHT
}

@export var run_speed: float = 6.8
@export var turn_speed: float = 12.0

@onready var visual_root: Node3D = $VisualRoot
@onready var body_mesh: MeshInstance3D = $VisualRoot/Body
@onready var head_root: Node3D = $VisualRoot/HeadRoot
@onready var lantern_node: Node3D = $VisualRoot/Lantern
@onready var lantern_light: OmniLight3D = $VisualRoot/Lantern/OmniLight3D

var state: ChickenState = ChickenState.IDLE
var has_lantern: bool = true
var player_ref: Node3D = null

var waypoints: Array[Vector3] = [
	Vector3(-4.5, 0.35, -2.5),
	Vector3(-1.0, 0.35, -5.5),
	Vector3(5.5, 0.35, -1.0),
	Vector3(8.5, 0.35, -4.5),
	Vector3(7.2, 0.35, -9.5)
]
var current_waypoint_idx: int = 0

var alert_timer: float = 0.0
var idle_bob_timer: float = 0.0
var cluck_timer: float = 3.0
var base_y: float = 0.35

func _ready() -> void:
	add_to_group("interactable")
	base_y = position.y

func _physics_process(delta: float) -> void:
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]

	match state:
		ChickenState.IDLE:
			_process_idle(delta)
		ChickenState.ALERT:
			_process_alert(delta)
		ChickenState.RUNNING:
			_process_running(delta)
		ChickenState.CORNERED:
			_process_cornered(delta)
		ChickenState.CAUGHT:
			_process_caught(delta)

	move_and_slide()

func _process_idle(delta: float) -> void:
	# Subtle comedic idle animations
	idle_bob_timer += delta
	if idle_bob_timer > 0.6:
		idle_bob_timer = 0.0
		if randf() > 0.5 and head_root:
			head_root.rotation.y = randf_range(-0.8, 0.8)
			head_root.rotation.x = randf_range(-0.3, 0.3)
	
	cluck_timer -= delta
	if cluck_timer <= 0.0:
		cluck_timer = randf_range(4.0, 8.0)
		SFX.play_chicken()

	# Check distance to player
	if player_ref and GameState.current_state >= GameState.State.CHICKEN_QUEST:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < 6.5:
			trigger_alert()

func trigger_alert() -> void:
	state = ChickenState.ALERT
	alert_timer = 0.45
	SFX.play_chicken()
	velocity.y = 3.5 # Panic hop
	if head_root:
		head_root.rotation.y = PI # Look back at player

func _process_alert(delta: float) -> void:
	# Fall back to ground
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	alert_timer -= delta
	if alert_timer <= 0.0:
		state = ChickenState.RUNNING
		current_waypoint_idx = 0

func _process_running(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	if current_waypoint_idx >= waypoints.size():
		state = ChickenState.CORNERED
		velocity.x = 0.0
		velocity.z = 0.0
		SFX.play_chicken()
		return

	var target_pos = waypoints[current_waypoint_idx]
	var dir = (target_pos - global_position)
	dir.y = 0.0
	
	if dir.length() < 0.8:
		current_waypoint_idx += 1
		return

	dir = dir.normalized()
	velocity.x = dir.x * run_speed
	velocity.z = dir.z * run_speed

	# Face movement direction
	var target_angle = atan2(-dir.x, -dir.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, turn_speed * delta)

	# Funny rapid waddle
	var run_time = Time.get_ticks_msec() * 0.025
	visual_root.position.y = abs(sin(run_time)) * 0.12
	visual_root.rotation.z = sin(run_time * 0.5) * 0.22

func _process_cornered(delta: float) -> void:
	# Heavy breathing / panting
	var pant_time = Time.get_ticks_msec() * 0.012
	visual_root.position.y = abs(sin(pant_time)) * 0.05
	visual_root.rotation.z = move_toward(visual_root.rotation.z, 0.0, delta * 2.0)
	
	# Lantern flickering
	if lantern_light:
		lantern_light.light_energy = 1.6 + sin(Time.get_ticks_msec() * 0.015) * 0.4

func _process_caught(delta: float) -> void:
	# Gentle idle
	var calm_time = Time.get_ticks_msec() * 0.003
	visual_root.position.y = sin(calm_time) * 0.02
	visual_root.rotation.z = 0.0

func get_interact_text() -> String:
	if has_lantern:
		if state == ChickenState.CORNERED:
			return "Catch Chicken & Take Lantern"
		elif GameState.current_state == GameState.State.START:
			return "Inspect Chicken"
		else:
			return "Catch Chicken"
	return "Exhausted Chicken"

func interact(player: Node) -> String:
	if GameState.current_state == GameState.State.START:
		SFX.play_chicken()
		return "Chicken: *clucks suspiciously and clings to a stolen lantern*"

	if has_lantern:
		has_lantern = false
		state = ChickenState.CAUGHT
		if lantern_node:
			lantern_node.visible = false
		
		SFX.play_lantern()
		SFX.play_chicken()
		
		GameState.set_state(GameState.State.LANTERN_FOUND)
		lantern_taken.emit()
		
		if player and player.has_method("show_status_message"):
			player.show_status_message("YOU GOT THE LANTERN.", 4.0)
		
		return "YOU GOT THE LANTERN."
	else:
		SFX.play_chicken()
		return "Chicken: *soft defeated cluck*"
