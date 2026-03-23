extends Node2D

signal health_changed(current, max)
signal died()

var max_health = 200
var health = 200
var stunned = false
var attack_cooldown = 1.6
var attack_timer = 0.5
var attack_variance = 0.9
var hit_flash = 0.0

func _ready():
	health_changed.emit(health, max_health)

func _process(delta):
	position.y = position.y + sin(Time.get_ticks_msec() / 600.0) * 0.0  # OS.get_ticks_msec() → Time.get_ticks_msec()
	if stunned:
		return
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown + randf() * attack_variance
		var lvl = get_parent()
		if lvl and lvl.has_node("Player"):
			var player = lvl.get_node("Player")
			var dir = (player.position - position).normalized()
			if lvl.has_method("spawn_enemy_projectile"):
				lvl.spawn_enemy_projectile(position + Vector2(0, -10), dir)

func _on_hit_flash():
	hit_flash = 0.25

func take_damage(amount):
	if stunned:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_on_death()

func _on_death():
	stunned = true
	queue_redraw()  # update() → queue_redraw()
	died.emit()

func _draw():
	if stunned:
		draw_rect(Rect2(Vector2(-60, -40), Vector2(120, 80)), Color(0.6, 0.1, 0.1))
		draw_line(Vector2(-30, -30), Vector2(-50, -70), Color(0.95, 0.8, 0.6), 8)
		draw_line(Vector2(30, -30), Vector2(50, -70), Color(0.95, 0.8, 0.6), 8)
	else:
		var base_col = Color(0.4, 0.0, 0.6)
		if hit_flash > 0.0:
			base_col = base_col.lightened(0.4)
		draw_rect(Rect2(Vector2(-80, -60), Vector2(160, 120)), base_col)
		for i in range(6):
			var x = -64 + i * 24
			draw_rect(Rect2(Vector2(x, -76), Vector2(10, 10)), Color(0.9, 0.2, 0.2))
