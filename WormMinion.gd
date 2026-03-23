extends Node2D

var health = 50
var speed = 80
var direction = Vector2(1, 0)

func _ready():
	set_process(true)

func _process(delta):
	position += direction * speed * delta
	# Simple AI: move toward player
	var lvl = get_parent().get_parent()
	if lvl and lvl.has_node("Player"):
		var player = lvl.get_node("Player")
		direction = (player.position - position).normalized()

func take_damage(amount):
	health -= amount
	if health <= 0:
		queue_free()

func _draw():
	draw_rect(Rect2(Vector2(-20, -15), Vector2(40, 30)), Color(0.5, 0.8, 0.2))
