extends CharacterBody2D

const SPEED = 300.0

# Durumlarımızı enum ile tanımlıyoruz
enum State { READY, START, LOOP, END }
var state: State = State.READY

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Animasyon loop ayarlarını garantiye alalım
	var f = anim.sprite_frames
	f.set_animation_loop("rogue_run_start", false)
	f.set_animation_loop("rogue_run_loop",  true)
	f.set_animation_loop("rogue_run_end",   false)
	f.set_animation_loop("rogue_ready_loop", true)

	# animation_finished sinyalini doğru Callable ile bağlayalım
	anim.animation_finished.connect(Callable(self, "_on_AnimatedSprite2D_animation_finished"))

	# Başlangıçta idle animasyonunu oynatalım
	anim.play("rogue_ready_loop")

func _physics_process(_delta: float) -> void:
	var dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var moving = dir != 0

	if moving:
		velocity.x = dir * SPEED
		# Sadece READY durumundaysa start oynat
		if state == State.READY:
			state = State.START
			anim.play("rogue_run_start")
	else:
		velocity.x = 0
		# Sadece START veya LOOP durumundaysa end oynat
		if state == State.START or state == State.LOOP:
			state = State.END
			anim.play("rogue_run_end")

	move_and_slide()

func _on_AnimatedSprite2D_animation_finished() -> void:
	match state:
		State.START:
			# Start bittiyse, hala hareket ediyorsak loop, değilse end
			if Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left") != 0:
				state = State.LOOP
				anim.play("rogue_run_loop")
			else:
				state = State.END
				anim.play("rogue_run_end")
		State.END:
			# End bittiğinde tekrar idle/ready durumuna dön
			state = State.READY
			anim.play("rogue_ready_loop")
		_:
			# READY veya LOOP durumlarında başka bir otomatik geçiş yok
			pass
