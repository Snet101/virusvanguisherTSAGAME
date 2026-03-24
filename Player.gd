extends Node2D

enum State { FALLING, RUBBING_HEAD, WALKING }
var state = State.FALLING
var velocity = Vector2.ZERO
var gravity = 900
var ground_y = 120
var walk_speed = 150
var jump_speed = -250
var facing = 1
var rub_timer = 0.0
var jumps_left = 2

signal fired(from_pos, direction)
signal landed()
signal damaged(current, max_hp)
signal ammo_changed(current, max_ammo)
signal died()

var max_health = 100
var health = max_health
var hit_flash = 0.0

var max_ammo = 10
var ammo = max_ammo

# Status timers
var slow_timer = 0.0
var invert_timer = 0.0
var invincible_timer = 0.0
var _inv_flash = 0.0

# Custom sprite
var has_custom_sprite = false

func take_damage(amount):
	if invincible_timer > 0.0:
		return
	health = max(0, health - amount)
	hit_flash = 0.3
	damaged.emit(health, max_health)
	if health <= 0:
		died.emit()
		queue_free()

func refill_ammo():
	ammo = max_ammo
	ammo_changed.emit(ammo, max_ammo)

func add_ammo(amount: int):
	ammo = min(max_ammo, ammo + amount)
	ammo_changed.emit(ammo, max_ammo)

func apply_slow(duration: float):
	slow_timer = max(slow_timer, duration)

func apply_invert(duration: float):
	invert_timer = max(invert_timer, duration)

func apply_invincible(duration: float):
	invincible_timer = max(invincible_timer, duration)

func _ready():
	pass

func start_falling():
	state = State.FALLING
	position.y = -60
	velocity = Vector2(0, 60)

func _process(delta):
	if slow_timer > 0.0:
		slow_timer = max(0.0, slow_timer - delta)
	if invert_timer > 0.0:
		invert_timer = max(0.0, invert_timer - delta)
	if invincible_timer > 0.0:
		invincible_timer = max(0.0, invincible_timer - delta)
		_inv_flash += delta * 10.0
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)

	var speed_mult = 0.4 if slow_timer > 0.0 else 1.0

	match state:
		State.FALLING:
			velocity.y += gravity * delta
			# Move left/right in air
			var air_dir = 0
			if Input.is_action_pressed("ui_left"):
				air_dir = -1
			elif Input.is_action_pressed("ui_right"):
				air_dir = 1
			if invert_timer > 0.0:
				air_dir = -air_dir
			if air_dir != 0:
				facing = air_dir
			position.x += air_dir * walk_speed * speed_mult * delta
			position.x = clamp(position.x, 2, 286)
			# Double jump
			var jump_key = "ui_up" if invert_timer <= 0.0 else "ui_down"
			if Input.is_action_just_pressed("ui_accept"):
				_try_fire()
			position += velocity * delta
			if position.y >= ground_y:
				position.y = ground_y
				velocity.y = 0.0
				_on_landed()

			var dir_x = 0
			if Input.is_action_pressed("ui_left"):
				dir_x = -1
			elif Input.is_action_pressed("ui_right"):
				dir_x = 1
			if invert_timer > 0.0:
				dir_x = -dir_x
			if dir_x != 0:
				facing = dir_x
			position.x += dir_x * walk_speed * speed_mult * delta
			position.x = clamp(position.x, 2, 286)

			var jump_key = "ui_up" if invert_timer <= 0.0 else "ui_down"
			if Input.is_action_just_pressed(jump_key):
				velocity.y = jump_speed
				jumps_left = 1
				state = State.FALLING

			if Input.is_action_just_pressed("ui_accept"):
				_try_fire()

	queue_redraw()

func _try_fire():
	if ammo <= 0:
		return
	ammo -= 1
	ammo_changed.emit(ammo, max_ammo)
	var muzzle = global_position + Vector2(20 * facing, 0)
	fired.emit(muzzle, Vector2(facing, 0))

func _on_landed():
	rub_timer = 0.0
	jumps_left = 2
	state = State.RUBBING_HEAD
	landed.emit()

func _draw():
	# If custom art is loaded, the Sprite2D child handles visuals
	if has_custom_sprite:
		return

	var a = 1.0
	if invincible_timer > 0.0:
		a = 0.5 + 0.5 * sin(_inv_flash)

	match state:
		State.FALLING:
			draw_circle(Vector2.ZERO, 12, Color(0.95, 0.8, 0.6, a))
			draw_circle(Vector2(0, 7), 7, Color(0.8, 0.3, 0.3, a))

		State.RUBBING_HEAD:
			var skin = Color(0.95, 0.8, 0.6, a)
			draw_circle(Vector2(0, -12), 7, skin)
			draw_rect(Rect2(Vector2(-7, -5), Vector2(14, 21)), Color(0.8, 0.2, 0.2, a))
			draw_line(Vector2(7, -12), Vector2(16, -8), skin, 2)

		State.WALKING:
			var skin  = Color(0.95, 0.8, 0.6, a)
			var shirt = Color(0.8, 0.2, 0.2, a) if hit_flash <= 0.0 else Color(1.0, 0.4, 0.4, a)
			if invincible_timer > 0.0:
				shirt = Color(1.0, 0.5, 0.0, a)
			var pants   = Color(0.15, 0.15, 0.35, a)
			var gun_col = Color(0.3, 0.6, 1.0, a)
			# Hair (14×6 px)
			draw_rect(Rect2(Vector2(-7, -21), Vector2(14, 6)), Color(0.1, 0.05, 0.05, a))
			# Head (radius 7)
			draw_circle(Vector2(0, -12), 7, skin)
			# Torso (14×14 px)
			draw_rect(Rect2(Vector2(-7, -5), Vector2(14, 14)), shirt)
			# Legs (14×9 px)
			draw_rect(Rect2(Vector2(-7, 9), Vector2(14, 9)), pants)
			# Water gun (14 px long)
			draw_rect(Rect2(Vector2(7 * facing, 3), Vector2(14 * facing, 5)), gun_col)
			# Status rings
			if invincible_timer > 0.0:
				draw_arc(Vector2(0, 0), 22, 0, TAU, 8, Color(1.0, 0.5, 0.0, 0.5 * a), 2.0)
			if slow_timer > 0.0:
				draw_arc(Vector2(0, 0), 20, 0, TAU, 8, Color(0.3, 0.3, 1.0, 0.4), 1.5)
			if invert_timer > 0.0:
				draw_circle(Vector2(0, -27), 4, Color(1.0, 0.0, 0.5, 0.7 * a))
