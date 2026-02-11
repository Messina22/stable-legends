extends CharacterBody2D

enum State { IDLE, WALKING }

const SPEED := 30.0
const IDLE_TIME_MIN := 1.0
const IDLE_TIME_MAX := 3.0
const STUCK_THRESHOLD := 5.0
const STUCK_TIME := 1.0
const ARRIVE_DISTANCE := 4.0
const WALK_FPS := 8.0
const FRAME_COUNT := 6

@export var bounds := Rect2(40, 40, 272, 560)

var state := State.IDLE
var target := Vector2.ZERO
var idle_timer := 0.0
var stuck_timer := 0.0
var current_direction := 0

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

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_build_sprite_frames()
	idle_timer = randf_range(0.0, IDLE_TIME_MAX)
	current_direction = 0
	sprite.play("idle_south")


func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	# Remove the "default" animation that SpriteFrames creates automatically
	frames.remove_animation("default")

	for dir_name in direction_names:
		# Walk animation: 6 frames, looping
		var walk_anim := "walk_%s" % dir_name
		frames.add_animation(walk_anim)
		frames.set_animation_speed(walk_anim, WALK_FPS)
		frames.set_animation_loop(walk_anim, true)
		for i in range(FRAME_COUNT):
			var path := "res://assets/sprites/horse/walk/%s_%d.png" % [dir_name, i]
			var tex := load(path) as Texture2D
			frames.add_frame(walk_anim, tex)

		# Idle animation: single frame (frame 0 of walk), no loop needed
		var idle_anim := "idle_%s" % dir_name
		frames.add_animation(idle_anim)
		frames.set_animation_speed(idle_anim, 1.0)
		frames.set_animation_loop(idle_anim, false)
		var idle_tex := load("res://assets/sprites/horse/walk/%s_0.png" % dir_name) as Texture2D
		frames.add_frame(idle_anim, idle_tex)

	sprite.sprite_frames = frames


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
		_play_walk_animation()


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
	_play_idle_animation()


func _pick_wander_target() -> void:
	target = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)


func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() < 1.0:
		return
	var best_index := 0
	var best_dot := -2.0
	var vel_norm := vel.normalized()
	for i in range(8):
		var d := vel_norm.dot(direction_vectors[i])
		if d > best_dot:
			best_dot = d
			best_index = i
	if best_index != current_direction:
		current_direction = best_index
		_play_walk_animation()


func _play_walk_animation() -> void:
	var anim_name := "walk_%s" % direction_names[current_direction]
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _play_idle_animation() -> void:
	sprite.play("idle_%s" % direction_names[current_direction])
