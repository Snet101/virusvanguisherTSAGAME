extends Node2D

var speed = 240
var direction = Vector2(1, 0)
var lifetime = 3.0
var age = 0.0
var damage = 16
var owner_is_player = true

func _process(delta):
	position += direction.normalized() * speed * delta
	age += delta
	if age >= lifetime:
		queue_free()
		return
	var root = get_parent().get_parent()
	if not root:
		return
	if owner_is_player:
		var rex = root.get_node_or_null("RansomwareRex")
		if rex and position.distance_to(rex.position) < 48:
			if rex.has_method("take_damage"):
				rex.take_damage(damage)
				if rex.has_method("_on_hit_flash"):
					rex._on_hit_flash()
			queue_free()
	else:
		var player = root.get_node_or_null("Player")
		if player and position.distance_to(player.position) < 20:
			if player.has_method("take_damage"):
				player.take_damage(damage)
			queue_free()

func _draw():
	# Godot 4 ternary: value_if_true if condition else value_if_false
	draw_circle(Vector2.ZERO, 4, Color(0.2, 0.6, 1.0) if owner_is_player else Color(0.9, 0.2, 0.2))
