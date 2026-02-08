extends CharacterBody2D

enum State { IDLE, WALKING }

const SPEED := 30.0
const IDLE_TIME_MIN := 1.0
const IDLE_TIME_MAX := 3.0
const STUCK_THRESHOLD := 5.0
const STUCK_TIME := 1.0
const ARRIVE_DISTANCE := 4.0

@export var bounds := Rect2(40, 40, 272, 560)

var state := State.IDLE
var target := Vector2.ZERO
var idle_timer := 0.0
var stuck_timer := 0.0

var direction_textures: Array[Texture2D] = []
# Order: S, SW, W, NW, N, NE, E, SE (matching PixelLab output)
var direction_names := ["south", "south_west", "west", "north_west", "north", "north_east", "east", "south_east"]
var direction_vectors: Array[Vector2] = [
	Vector2(0, 1),    # S
	Vector2(-1, 1).normalized(),  # SW
	Vector2(-1, 0),   # W
	Vector2(-1, -1).normalized(), # NW
	Vector2(0, -1),   # N
	Vector2(1, -1).normalized(),  # NE
	Vector2(1, 0),    # E
	Vector2(1, 1).normalized(),   # SE
]

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_load_direction_textures()
	idle_timer = randf_range(0.0, IDLE_TIME_MAX)
	_set_direction_index(0)  # Default: south


func _load_direction_textures() -> void:
	direction_textures.resize(8)
	for i in range(8):
		var path := "res://assets/sprites/horse/%s.png" % direction_names[i]
		direction_textures[i] = load(path)


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_process_idle(delta)
		State.WALKING:
			_process_walking(delta)


func _process_idle(delta: float) -> void:
	idle_timer -= delta
	if idle_timer <= 0.0:
		_pick_wander_target()
		state = State.WALKING
		stuck_timer = 0.0


func _process_walking(delta: float) -> void:
	var direction := (target - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

	_update_facing(velocity)

	# Check if arrived
	if global_position.distance_to(target) < ARRIVE_DISTANCE:
		_enter_idle()
		return

	# Stuck detection
	if get_real_velocity().length() < STUCK_THRESHOLD:
		stuck_timer += delta
		if stuck_timer >= STUCK_TIME:
			_enter_idle()
	else:
		stuck_timer = 0.0


func _enter_idle() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	idle_timer = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)


func _pick_wander_target() -> void:
	target = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)


func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() < 1.0:
		return
	# Find closest direction vector
	var best_index := 0
	var best_dot := -2.0
	var vel_norm := vel.normalized()
	for i in range(8):
		var d := vel_norm.dot(direction_vectors[i])
		if d > best_dot:
			best_dot = d
			best_index = i
	_set_direction_index(best_index)


func _set_direction_index(index: int) -> void:
	if direction_textures[index]:
		sprite.texture = direction_textures[index]
