extends CharacterBody2D

const SPEED              = 250.0
const GRAVITY            = 700.0      # px/sec²
const JUMP_VELOCITY      = -500.0     # px/sec
const DEFAULT_SNAP_LENGTH = 20.0       # how far to snap to one-way floors

enum State { READY, START, LOOP, END }
var state: State = State.READY
var snap_length: float = DEFAULT_SNAP_LENGTH  # Declare snap_length as a variable

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# — animation loop setup —
	var f = anim.sprite_frames
	f.set_animation_loop("rogue_run_start", false)
	f.set_animation_loop("rogue_run_loop", true)
	f.set_animation_loop("rogue_run_end", false)
	f.set_animation_loop("rogue_ready_loop", true)
	anim.animation_finished.connect(self._on_AnimatedSprite2D_animation_finished)
	anim.play("rogue_ready_loop")

	# — slope & snap settings —
	floor_stop_on_slope = false           # let gravity win on slopes
	floor_max_angle = deg_to_rad(45)      # steepest “floor” you can stand on
	floor_snap_length = DEFAULT_SNAP_LENGTH  # Use built-in floor_snap_length

func _physics_process(delta: float) -> void:
	# — 1) gravity —
	velocity.y += GRAVITY * delta

	# — 2) horizontal & flip —
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if dir != 0:
		anim.flip_h = dir < 0
		velocity.x = dir * SPEED
		if state == State.READY:
			state = State.START
			anim.play("rogue_run_start")
	else:
		velocity.x = 0
		if state in [State.START, State.LOOP]:
			state = State.END
			anim.play("rogue_run_end")

	# — 3) jump —
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# — 4) drop-through one-way platforms —
	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		floor_snap_length = 0.0
	else:
		floor_snap_length = DEFAULT_SNAP_LENGTH

	# — 5) move & slide —
	move_and_slide()  # No need to assign, as it returns bool in Godot 4

func _on_AnimatedSprite2D_animation_finished() -> void:
	match state:
		State.START:
			var d2 = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
			if d2 != 0:
				state = State.LOOP
				anim.play("rogue_run_loop")
			else:
				state = State.END
				anim.play("rogue_run_end")
		State.END:
			state = State.READY
			anim.play("rogue_ready_loop")
		_:
			pass
