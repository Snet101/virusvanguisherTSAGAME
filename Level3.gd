extends Node2D
# Level 3: The Core — boss splits on hit, defeat all with charged blasts
@onready var player = $Player
@onready var king = $WormKing
@onready var enemies = $Enemies
@onready var health_bg = $UI/BossHealthBG
@onready var health_bar = $UI/BossHealthBG/BossHealthBar
@onready var player_health_bar = $UI/PlayerHealthBG/PlayerHealthBar
@onready var audio_node = $Audio
@onready var projectiles = $Projectiles
const VIEW_WIDTH = 288
const VIEW_HEIGHT = 162
func _ready():
	_ensure_placeholders()
	king.health_changed.connect(_on_king_health_changed)
	king.died.connect(_on_king_died)
	king.split.connect(_on_king_split)
	player.fired.connect(_on_player_fired)
	player.landed.connect(_on_player_landed)
	player.damaged.connect(_on_player_damaged)
	player.call_deferred("start_falling")
func _on_king_health_changed(current, max):
	var pct = clamp(float(current) / float(max), 0.0, 1.0)
	var inner_max_w = health_bg.size.x - 12
	health_bar.size.x = int(inner_max_w * pct)
func _on_player_damaged(current, max):
	var pct = clamp(float(current) / float(max), 0.0, 1.0)
	var inner_max_w = $UI/PlayerHealthBG.size.x - 12
	player_health_bar.size.x = int(inner_max_w * pct)
func _on_king_died():
	health_bar.color = Color(0.2, 0.9, 0.3)
	print("Game Complete!")
func _on_king_split(pos, count):
	for i in range(count):
		var e = Node2D.new()
		e.set_script(load("res://WormMinion.gd"))
		e.position = pos + Vector2(randf() * 40 - 20, randf() * 40 - 20)
		enemies.add_child(e)
func _on_player_fired(from_pos, direction):
	spawn_player_projectile(from_pos, direction, true)
	if audio_node and audio_node.has_node("SFX_Charge"):
		var sfx = audio_node.get_node("SFX_Charge")
		if sfx and sfx.stream:
			sfx.play()
func _on_player_landed():
	if audio_node and audio_node.has_node("SFX_Land"):
		var sl = audio_node.get_node("SFX_Land")
		if sl and sl.stream:
			sl.play()
func spawn_player_projectile(from_pos, direction, charged = false):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.position = from_pos
	p.direction = direction
	p.owner_is_player = true
	p.damage = 25 if charged else 16
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
	var king_path = assets_dir + "king.png"
	var bg_path = assets_dir + "background3.png"
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
	var ksprite: Sprite2D = null
	if king.has_node("Sprite2D"):
		ksprite = king.get_node("Sprite2D")
	else:
		ksprite = Sprite2D.new()
		ksprite.name = "Sprite2D"
		king.add_child(ksprite)
	if ResourceLoader.exists(king_path):
		ksprite.texture = load(king_path)
	else:
		ksprite.texture = _make_tex(Color(0.5, 0.8, 0.2, 1), 160, 120)
	if audio_node:
		if audio_node.has_node("SFX_Charge"):
			audio_node.get_node("SFX_Charge").stream = _make_silence()
		if audio_node.has_node("SFX_Split"):
			audio_node.get_node("SFX_Split").stream = _make_silence()
