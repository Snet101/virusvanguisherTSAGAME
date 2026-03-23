extends Node2D
signal health_changed(current, max)
signal died()
signal split(pos, count)
var max_health = 300
var health = 300
var stunned = false
var attack_cooldown = 2.5
var attack_timer = 1.5
var attack_variance = 1.5
var hit_flash = 0.0
var splits_left = 3
func _ready():
	health_changed.emit(health, max_health)
func _process(delta):
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
func take_damage(amount):
	if stunned:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0:
		_on_death()
	else:
		hit_flash = 0.25
		if splits_left > 0:
			splits_left -= 1
			split.emit(position, 2)
			# grab audio_node from parent level
			var lvl = get_parent()
			if lvl and lvl.has_node("Audio"):
				var audio_node = lvl.get_node("Audio")
				if audio_node.has_node("SFX_Split"):
					var sfx = audio_node.get_node("SFX_Split")
					if sfx and sfx.stream:
						sfx.play()
func _on_death():
	stunned = true
	queue_redraw()  # update() → queue_redraw()
	died.emit()
func _draw():
	if stunned:
		draw_rect(Rect2(Vector2(-60, -40), Vector2(120, 80)), Color(0.5, 0.8, 0.2))
		draw_line(Vector2(-30, -30), Vector2(-50, -70), Color(0.95, 0.8, 0.6), 8)
		draw_line(Vector2(30, -30), Vector2(50, -70), Color(0.95, 0.8, 0.6), 8)
	else:
		var base_col = Color(0.5, 0.8, 0.2)
		if hit_flash > 0.0:
			base_col = base_col.lightened(0.4)
		draw_rect(Rect2(Vector2(-80, -60), Vector2(160, 120)), base_col)
		for i in range(10):
			var x = -70 + i * 14
			draw_rect(Rect2(Vector2(x, -76), Vector2(8, 8)), Color(0.7, 0.9, 0.4))
