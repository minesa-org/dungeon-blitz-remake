extends CharacterBody2D

const SPEED              = 250.0
const GRAVITY            = 700.0      # px/sec²
const JUMP_VELOCITY      = -500.0     # px/sec
const DEFAULT_SNAP_LENGTH = 20.0       # how far to snap to one-way floors

enum State { READY, START, LOOP, END, JUMP_START, JUMP_LOOP, JUMP_END }
var state: State = State.READY
var snap_length: float = DEFAULT_SNAP_LENGTH
var was_on_floor: bool = false
var just_jumped: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_movement_grass: AudioStreamPlayer = $sfx_movement_grass
@onready var sfx_jump: AudioStreamPlayer = $sfx_jump

func _ready() -> void:
	# Animation loop setup
	var f = anim.sprite_frames
	f.set_animation_loop("rogue_run_start", false)
	f.set_animation_loop("rogue_run_loop", true)
	f.set_animation_loop("rogue_run_end", false)
	f.set_animation_loop("rogue_ready_loop", true)
	f.set_animation_loop("rogue_jump_start", false)
	f.set_animation_loop("rogue_jump_loop", true)
	f.set_animation_loop("rogue_jump_end", false)
	
	# Connect animation_finished signal
	if not anim.animation_finished.is_connected(self._on_AnimatedSprite2D_animation_finished):
		anim.animation_finished.connect(self._on_AnimatedSprite2D_animation_finished)
	
	anim.play("rogue_ready_loop")

	# Slope & snap settings
	floor_stop_on_slope = false
	floor_max_angle = deg_to_rad(45)
	floor_snap_length = DEFAULT_SNAP_LENGTH

func _physics_process(delta: float) -> void:
	# — 1) gravity —
	velocity.y += GRAVITY * delta

	# — 2) horizontal & flip —
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if dir != 0:
		anim.flip_h = dir < 0
		velocity.x = dir * SPEED
	else:
		velocity.x = 0

	# — 3) jump —
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		state = State.JUMP_START
		anim.play("rogue_jump_start")
		sfx_jump.play()
		just_jumped = true

	# — 4) drop-through one-way platforms —
	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		floor_snap_length = 0.0
	else:
		floor_snap_length = DEFAULT_SNAP_LENGTH

	# — 5) move & slide —
	move_and_slide()

	# — 6) handle animation states —
	if not is_on_floor():
		if state not in [State.JUMP_START, State.JUMP_LOOP]:
			state = State.JUMP_LOOP
			anim.play("rogue_jump_loop")
	elif is_on_floor():
		if (state == State.JUMP_LOOP) or (state == State.JUMP_START and not just_jumped):
			state = State.JUMP_END
			anim.play("rogue_jump_end")
		elif dir != 0:
			if state == State.READY or state == State.END:
				state = State.START
				anim.play("rogue_run_start")
		else:
			if state in [State.START, State.LOOP]:
				state = State.END
				anim.play("rogue_run_end")

	# — 7) play grass movement sound —
	if is_on_floor() and velocity.x != 0:
		if not sfx_movement_grass.playing:
			sfx_movement_grass.play()
	else:
		if sfx_movement_grass.playing:
			sfx_movement_grass.stop()

	# — 8) reset just_jumped —
	just_jumped = false

	# — 9) update floor state —
	was_on_floor = is_on_floor()

func _on_AnimatedSprite2D_animation_finished() -> void:
	match state:
		State.JUMP_START:
			if not is_on_floor():
				state = State.JUMP_LOOP
				anim.play("rogue_jump_loop")
			else:
				state = State.JUMP_END
				anim.play("rogue_jump_end")
		State.JUMP_END:
			state = State.READY
			anim.play("rogue_ready_loop")
		State.START:
			state = State.LOOP
			anim.play("rogue_run_loop")
		State.END:
			state = State.READY
			anim.play("rogue_ready_loop")
		_:
			pass
