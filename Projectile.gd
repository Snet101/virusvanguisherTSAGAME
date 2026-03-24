extends Node2D

var speed = 260
var direction = Vector2(1, 0)
var lifetime = 3.0
var age = 0.0
var damage = 16
var owner_is_player = true

# Engulf DoT
var is_engulf = false
var dot_timer = 0.0
var _engulf_entered = false   # true on first contact
const DOT_INTERVAL = 0.25    # damage tick rate
const ENGULF_RADIUS = 28.0

func _process(delta):
	# Enemy proj slower for dodging
	var proj_speed = 200 if not owner_is_player else speed
	position += direction.normalized() * proj_speed * delta
	age += delta
	if age >= lifetime:
		queue_free()
		return

	if position.x < -30 or position.x > 320 or position.y < -30 or position.y > 200:
		queue_free()
		return

	var root = get_parent().get_parent()
	if not root:
		return

	if owner_is_player:
		_try_hit_bosses(root)
		_try_hit_enemies(root)
	else:
		_try_hit_player(root, delta)

	queue_redraw()

func _try_hit_bosses(root):
	for boss_name in ["RansomwareRex", "TrojanTitan", "WormKing"]:
		var boss = root.get_node_or_null(boss_name)
		if not boss:
			continue
		if boss.get("stunned") == true:
			continue
		if position.distance_to(boss.position) < 50:
			if boss.has_method("take_damage"):
				boss.take_damage(damage)
			if boss.has_method("_on_hit_flash"):
				boss._on_hit_flash()
			queue_free()
			return

func _try_hit_enemies(root):
	var enemies = root.get_node_or_null("Enemies")
	if not enemies:
		return
	for enemy in enemies.get_children():
		if position.distance_to(enemy.position) < 18:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			queue_free()
			return

func _try_hit_player(root, delta):
	var player = root.get_node_or_null("Player")
	if not player:
		return

	var dist = position.distance_to(player.position)
	var radius = ENGULF_RADIUS if is_engulf else 18.0

	if dist < radius:
		if is_engulf:
		# Instant hit, then DoT
		if not _engulf_entered:
			_engulf_entered = true
			dot_timer = 0.0
			if player.has_method("take_damage"):
				player.take_damage(damage)
		# Tick damage
			dot_timer += delta
			if dot_timer >= DOT_INTERVAL:
				dot_timer = 0.0
				if player.has_method("take_damage"):
					player.take_damage(damage)
		else:
			if player.has_method("take_damage"):
				player.take_damage(damage)
			queue_free()
	else:
		if is_engulf:
			dot_timer = 0.0
			_engulf_entered = false  # reset for re-entry

func _draw():
	if is_engulf:
		# Pulsing blob
		var pulse = 0.75 + 0.25 * sin(age * 7.0)
		var r = ENGULF_RADIUS * pulse
		draw_circle(Vector2.ZERO, r, Color(0.25, 0.75, 0.1, 0.55))
		draw_circle(Vector2.ZERO, r * 0.6, Color(0.4, 0.9, 0.15, 0.75))
		# Tentacles
		for i in range(5):
			var angle = i * TAU / 5.0 + age * 3.0
			var tip = Vector2(cos(angle), sin(angle)) * (r + 8.0 * pulse)
			draw_line(Vector2.ZERO, tip, Color(0.3, 0.85, 0.1, 0.5), 2)
		# Eyes
		draw_circle(Vector2(-3, -2), 3, Color(0.9, 0.95, 0.1))
		draw_circle(Vector2(3, -2), 3, Color(0.9, 0.95, 0.1))
		draw_circle(Vector2(-3, -2), 1.5, Color(0.0, 0.0, 0.0))
		draw_circle(Vector2(3, -2), 1.5, Color(0.0, 0.0, 0.0))
	elif owner_is_player:
		draw_circle(Vector2.ZERO, 4, Color(0.3, 0.7, 1.0))
		draw_circle(Vector2.ZERO, 2, Color(0.8, 0.95, 1.0))
	else:
		draw_circle(Vector2.ZERO, 3, Color(0.9, 0.2, 0.1))
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color(1.0, 0.5, 0.1), 1)
		draw_line(Vector2(0, -4), Vector2(0, 4), Color(1.0, 0.5, 0.1), 1)
