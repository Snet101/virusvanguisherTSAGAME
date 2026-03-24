extends Node2D

# Collectible types for Level 2 — The Corrupted City
# FAKE traps: GIFT_BOX, GREEN_SHIELD, SPAM_EMAIL  (glitch/flicker)
# REAL power-ups: WATER_BOTTLE, ORANGE_SHIELD, FLOPPY_DISK (steady glow)

enum Type {
	GIFT_BOX,     # Fake — spawns 3 mini viruses
	GREEN_SHIELD, # Fake — slows player for 5 s
	SPAM_EMAIL,   # Fake — inverts controls for 4 s
	WATER_BOTTLE, # Real — refills ammo
	ORANGE_SHIELD,# Real — 5 s invincibility
	FLOPPY_DISK,  # Real — clears all enemies
}

var collectible_type: int = Type.WATER_BOTTLE
var collected = false
var _bob = 0.0
var _glitch_t = 0.0
var _glitch_on = false
var _glitch_next = 0.3
const PICK_RADIUS = 14.0

func _process(delta):
	if collected:
		return
	_bob += delta * 2.2

	# Fake collectibles glitch randomly
	if collectible_type in [Type.GIFT_BOX, Type.GREEN_SHIELD, Type.SPAM_EMAIL]:
		_glitch_t += delta
		if _glitch_t >= _glitch_next:
			_glitch_t = 0.0
			_glitch_on = !_glitch_on
			_glitch_next = randf_range(0.08, 0.45)

	queue_redraw()

	# Check player proximity
	var level = get_parent().get_parent()
	if not level:
		return
	var player = level.get_node_or_null("Player")
	if player and global_position.distance_to(player.global_position) < PICK_RADIUS:
		_on_collected(player, level)

func _on_collected(player, level):
	collected = true
	match collectible_type:
		Type.GIFT_BOX:
			# Spawn 3 mini viruses
			for i in range(3):
				if level.has_method("spawn_mini_virus"):
					var offset = Vector2(cos(i * TAU / 3) * 20, sin(i * TAU / 3) * 20)
					level.spawn_mini_virus(global_position + offset)

		Type.GREEN_SHIELD:
			if player.has_method("apply_slow"):
				player.apply_slow(5.0)

		Type.SPAM_EMAIL:
			if player.has_method("apply_invert"):
				player.apply_invert(4.0)

		Type.WATER_BOTTLE:
			if player.has_method("add_ammo"):
				player.add_ammo(4)

		Type.ORANGE_SHIELD:
			if player.has_method("apply_invincible"):
				player.apply_invincible(5.0)

		Type.FLOPPY_DISK:
			if level.has_method("clear_enemies"):
				level.clear_enemies()

	queue_free()

# ── Drawing ──────────────────────────────────────────────────────────────────

func _draw():
	if collected:
		return
	var y = sin(_bob) * 3.0   # bobbing offset

	match collectible_type:
		Type.GIFT_BOX:      _draw_gift_box(y)
		Type.GREEN_SHIELD:  _draw_green_shield(y)
		Type.SPAM_EMAIL:    _draw_spam_email(y)
		Type.WATER_BOTTLE:  _draw_water_bottle(y)
		Type.ORANGE_SHIELD: _draw_orange_shield(y)
		Type.FLOPPY_DISK:   _draw_floppy_disk(y)

func _draw_gift_box(y):
	var gx = randf_range(-2, 2) if _glitch_on else 0.0
	var o = Vector2(gx, y)
	# Box body
	draw_rect(Rect2(o + Vector2(-9, -6), Vector2(18, 15)), Color(0.85, 0.15, 0.15))
	# Lid
	draw_rect(Rect2(o + Vector2(-10, -11), Vector2(20, 6)), Color(0.7, 0.1, 0.1))
	# Ribbon
	draw_rect(Rect2(o + Vector2(-2, -11), Vector2(4, 15)), Color(1.0, 0.9, 0.1))
	draw_rect(Rect2(o + Vector2(-10, -8), Vector2(20, 3)), Color(1.0, 0.9, 0.1))
	# Bow knot circles
	draw_circle(o + Vector2(-4, -13), 3, Color(1.0, 0.9, 0.1))
	draw_circle(o + Vector2(4, -13), 3, Color(1.0, 0.9, 0.1))
	# Glitch stripe — gives it away as a trap
	if _glitch_on:
		draw_rect(Rect2(o + Vector2(-10, -3), Vector2(20, 3)), Color(0.1, 1.0, 0.3, 0.7))
	# Border
	draw_rect(Rect2(o + Vector2(-10, -11), Vector2(20, 20)), Color(0, 0, 0, 0), false)

func _draw_green_shield(y):
	var o = Vector2(0, y)
	# Shield shape
	draw_rect(Rect2(o + Vector2(-8, -11), Vector2(16, 16)), Color(0.1, 0.75, 0.2))
	draw_rect(Rect2(o + Vector2(-5, 5), Vector2(10, 5)), Color(0.1, 0.75, 0.2))
	draw_rect(Rect2(o + Vector2(-2, 10), Vector2(4, 3)), Color(0.1, 0.75, 0.2))
	# Alternates between checkmark (safe-looking) and X (danger)
	if _glitch_on:
		draw_line(o + Vector2(-4, -4), o + Vector2(4, 4), Color(0.9, 0.1, 0.1), 2)
		draw_line(o + Vector2(4, -4), o + Vector2(-4, 4), Color(0.9, 0.1, 0.1), 2)
	else:
		draw_line(o + Vector2(-4, 0), o + Vector2(-1, 4), Color(1, 1, 1), 2)
		draw_line(o + Vector2(-1, 4), o + Vector2(5, -4), Color(1, 1, 1), 2)

func _draw_spam_email(y):
	var gx = randf_range(-1, 1) if _glitch_on else 0.0
	var o = Vector2(gx, y)
	# Envelope body
	draw_rect(Rect2(o + Vector2(-10, -6), Vector2(20, 14)), Color(0.9, 0.85, 0.3))
	# Flap lines
	draw_line(o + Vector2(-10, -6), o + Vector2(0, 2), Color(0.6, 0.55, 0.1), 1)
	draw_line(o + Vector2(10, -6), o + Vector2(0, 2), Color(0.6, 0.55, 0.1), 1)
	# Star badge — glitches to ! when suspicious
	var star_col = Color(0.9, 0.2, 0.1) if _glitch_on else Color(1.0, 0.55, 0.0)
	draw_circle(o + Vector2(7, -10), 4, star_col)
	draw_line(o + Vector2(7, -13), o + Vector2(7, -8), Color(1, 1, 1), 1)
	draw_circle(o + Vector2(7, -7), 1, Color(1, 1, 1))
	# Glitch stripe
	if _glitch_on:
		draw_rect(Rect2(o + Vector2(-10, -1), Vector2(20, 2)), Color(0.2, 1.0, 0.4, 0.6))

func _draw_water_bottle(y):
	var o = Vector2(0, y)
	# Stable glow — no flickering
	var glow = 0.18 + 0.08 * sin(_bob)
	draw_circle(o, 12, Color(0.2, 0.5, 1.0, glow))
	# Bottle body
	draw_rect(Rect2(o + Vector2(-5, -7), Vector2(10, 16)), Color(0.4, 0.7, 1.0))
	# Cap
	draw_rect(Rect2(o + Vector2(-3, -11), Vector2(6, 5)), Color(0.2, 0.35, 0.9))
	# Water droplet symbol
	draw_circle(o + Vector2(0, 2), 3, Color(0.8, 0.95, 1.0))
	draw_line(o + Vector2(0, -1), o + Vector2(0, -5), Color(0.8, 0.95, 1.0), 1)

func _draw_orange_shield(y):
	var o = Vector2(0, y)
	# Warm pulsing glow — steady, trustworthy
	var glow = 0.25 + 0.12 * sin(_bob * 1.5)
	draw_circle(o, 14, Color(1.0, 0.45, 0.0, glow))
	# Shield body
	draw_rect(Rect2(o + Vector2(-9, -12), Vector2(18, 17)), Color(0.9, 0.38, 0.0))
	draw_rect(Rect2(o + Vector2(-6, 5), Vector2(12, 5)), Color(0.9, 0.38, 0.0))
	draw_rect(Rect2(o + Vector2(-3, 10), Vector2(6, 3)), Color(0.9, 0.38, 0.0))
	# Flame icon in center
	draw_circle(o + Vector2(0, -2), 4, Color(1.0, 0.7, 0.1))
	draw_circle(o + Vector2(0, -5), 2, Color(1.0, 0.9, 0.4))

func _draw_floppy_disk(y):
	var o = Vector2(0, y)
	# Disk body — steady spin, no distortion
	draw_rect(Rect2(o + Vector2(-9, -10), Vector2(18, 20)), Color(0.65, 0.65, 0.7))
	# Label area
	draw_rect(Rect2(o + Vector2(-7, -10), Vector2(14, 8)), Color(0.9, 0.9, 0.95))
	# Metal shutter slot
	draw_rect(Rect2(o + Vector2(-5, 1), Vector2(10, 6)), Color(0.45, 0.45, 0.5))
	# Wrench icon on label
	draw_line(o + Vector2(-3, -8), o + Vector2(2, -3), Color(0.35, 0.35, 0.4), 2)
	draw_circle(o + Vector2(-4, -9), 2, Color(0.35, 0.35, 0.4))
	draw_circle(o + Vector2(3, -2), 2, Color(0.35, 0.35, 0.4))
