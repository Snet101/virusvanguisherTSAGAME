extends Node2D

enum State { FALLING, RUBBING_HEAD, WALKING, PILOTING }
var state = State.FALLING
var velocity = Vector2.ZERO
var gravity = 900
var ground_y = 120
var walk_speed = 120
var jump_speed = -220
var facing = 1
var rub_timer = 0.0  # replaces the has_meta/get_meta approach

signal fired(from_pos, direction)
signal landed()
signal damaged(current, max_hp)

var max_health = 100
var health = max_health
var hit_flash = 0.0

func take_damage(amount):
	health = max(0, health - amount)
	hit_flash = 0.28
	damaged.emit(health, max_health)
	if health <= 0:
		queue_free()

func _ready():
	pass

func start_falling():
	state = State.FALLING
	position.y = -60
	velocity = Vector2(0, 60)

func _process(delta):
	match state:
		State.FALLING:
			velocity.y += gravity * delta
			position += velocity * delta
			if position.y >= ground_y:
				position.y = ground_y
				_on_landed()
		State.RUBBING_HEAD:
			rub_timer += delta
			if rub_timer >= 1.1:
				state = State.WALKING
		State.WALKING:
			var dir = Vector2.ZERO
			if Input.is_action_pressed("ui_left"):
				dir.x = -1
				facing = -1
			elif Input.is_action_pressed("ui_right"):
				dir.x = 1
				facing = 1
			else:
				dir.x = 0
			position.x += dir.x * walk_speed * delta
			if Input.is_action_just_pressed("ui_up"):
				velocity.y = jump_speed
				state = State.FALLING
			if Input.is_action_just_pressed("ui_accept"):
				var muzzle = global_position + Vector2(14 * facing, -6)
				fired.emit(muzzle, Vector2(facing, 0))
				queue_redraw()
		State.PILOTING:
			pass

func _on_landed():
	rub_timer = 0.0  # reset the timer each time we land
	state = State.RUBBING_HEAD
	queue_redraw()
	landed.emit()

func _draw():
	if state == State.FALLING:
		draw_circle(Vector2.ZERO, 14, Color(0.2, 0.6, 1.0))
	elif state == State.RUBBING_HEAD:
		draw_rect(Rect2(Vector2(-10, -8), Vector2(20, 24)), Color(0.9, 0.8, 0.6))
		draw_circle(Vector2(0, -12), 8, Color(0.95, 0.8, 0.6))
		draw_line(Vector2(6, -12), Vector2(10, -8), Color(0.9, 0.8, 0.6), 4)
	elif state == State.WALKING:
		draw_rect(Rect2(Vector2(-10, -8), Vector2(20, 24)), Color(0.2, 0.8, 0.3))
		draw_circle(Vector2(0, -12), 7, Color(0.95, 0.8, 0.6))
	elif state == State.PILOTING:
		draw_rect(Rect2(Vector2(-22, -8), Vector2(44, 18)), Color(0.15, 0.15, 0.6))
		draw_rect(Rect2(Vector2(12, -4), Vector2(18, 6)), Color(0.2, 0.6, 0.95))
		draw_circle(Vector2(-8, 8), 6, Color(0, 0, 0))
		draw_circle(Vector2(8, 8), 6, Color(0, 0, 0))
