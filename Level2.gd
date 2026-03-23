extends Node2D
# Level 2: The Corrupted City — dodge fake collectibles, grab real power-ups
@onready var player = $Player
@onready var titan = $TrojanTitan
@onready var collectibles = $Collectibles
@onready var health_bg = $UI/BossHealthBG
@onready var health_bar = $UI/BossHealthBG/BossHealthBar
@onready var player_health_bar = $UI/PlayerHealthBG/PlayerHealthBar
@onready var audio_node = $Audio
@onready var projectiles = $Projectiles
const VIEW_WIDTH = 288
const VIEW_HEIGHT = 162
func _ready():
	_ensure_placeholders()
	titan.health_changed.connect(_on_titan_health_changed)
	titan.died.connect(_on_titan_died)
	player.fired.connect(_on_player_fired)
	player.landed.connect(_on_player_landed)
	player.damaged.connect(_on_player_damaged)
	player.call_deferred("start_falling")
	_spawn_collectibles()
func _on_titan_health_changed(current, max):
	var pct = clamp(float(current) / float(max), 0.0, 1.0)
	var inner_max_w = health_bg.size.x - 12
	health_bar.size.x = int(inner_max_w * pct)
func _on_player_damaged(current, max):
	var pct = clamp(float(current) / float(max), 0.0, 1.0)
	var inner_max_w = $UI/PlayerHealthBG.size.x - 12
	player_health_bar.size.x = int(inner_max_w * pct)
func _on_titan_died():
	health_bar.color = Color(0.2, 0.9, 0.3)
	call_deferred("_go_to_level_three")
func _on_player_fired(from_pos, direction):
	spawn_player_projectile(from_pos, direction)
	if audio_node and audio_node.has_node("SFX_Shoot"):
		var sfx = audio_node.get_node("SFX_Shoot")
		if sfx and sfx.stream:
			sfx.play()
func _on_player_landed():
	if audio_node and audio_node.has_node("SFX_Land"):
		var sl = audio_node.get_node("SFX_Land")
		if sl and sl.stream:
			sl.play()
func _spawn_collectibles():
	for i in range(10):
		var c = Node2D.new()
		c.position = Vector2(randf() * VIEW_WIDTH, randf() * VIEW_HEIGHT)
		c.set_meta("is_fake", randf() > 0.5)
		collectibles.add_child(c)
func _go_to_level_three():
	get_tree().change_scene_to_file("res://Level3.tscn")
func spawn_player_projectile(from_pos, direction):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.position = from_pos
	p.direction = direction
	p.owner_is_player = true
	projectiles.add_child(p)
func spawn_enemy_projectile(from_pos, direction):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.position = from_pos
	p.direction = direction
	p.owner_is_player = false
	projectiles.add_child(p)
func _make_tex(col: Color, w: int, h: int) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			img.set_pixel(x, y, col)
	var tex = ImageTexture.create_from_image(img)
	return tex
func _make_silence() -> AudioStreamWAV:
	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	sample.stereo = false
	sample.loop_mode = AudioStreamWAV.LOOP_DISABLED
	sample.data = PackedByteArray()
	return sample
func _ensure_placeholders():
	var assets_dir = "res://assets/"
	var player_path = assets_dir + "player.png"
	var titan_path = assets_dir + "titan.png"
	var bg_path = assets_dir + "background2.png"
	if has_node("Background"):
		var bg = get_node("Background")
		if ResourceLoader.exists(bg_path):
			bg.texture = load(bg_path)
	var psprite: Sprite2D = null
	if player.has_node("Sprite2D"):
		psprite = player.get_node("Sprite2D")
	else:
		psprite = Sprite2D.new()
		psprite.name = "Sprite2D"
		player.add_child(psprite)
	if ResourceLoader.exists(player_path):
		psprite.texture = load(player_path)
	else:
		psprite.texture = _make_tex(Color(0.2, 0.6, 1.0, 1), 32, 32)
	var tsprite: Sprite2D = null
	if titan.has_node("Sprite2D"):
		tsprite = titan.get_node("Sprite2D")
	else:
		tsprite = Sprite2D.new()
		tsprite.name = "Sprite2D"
		titan.add_child(tsprite)
	if ResourceLoader.exists(titan_path):
		tsprite.texture = load(titan_path)
	else:
		tsprite.texture = _make_tex(Color(0.8, 0.4, 0.0, 1), 160, 120)
	if audio_node:
		if audio_node.has_node("SFX_Collect"):
			audio_node.get_node("SFX_Collect").stream = _make_silence()
		if audio_node.has_node("SFX_Hurt"):
			audio_node.get_node("SFX_Hurt").stream = _make_silence()
