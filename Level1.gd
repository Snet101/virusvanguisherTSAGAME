extends Node2D

# Level 1: Firewall Forest — basic flow and UI hookups
@onready var player = $Player
@onready var rex = $RansomwareRex
@onready var health_bg = $UI/BossHealthBG
@onready var health_bar = $UI/BossHealthBG/BossHealthBar
@onready var projectiles = $Projectiles

const VIEW_WIDTH = 288
const VIEW_HEIGHT = 162
@onready var player_health_bar = $UI/PlayerHealthBG/PlayerHealthBar
@onready var audio_node = $Audio

func _ready():
	_ensure_placeholders()

	# Godot 4: use signal.connect(callable) instead of connect("signal", self, "method")
	rex.health_changed.connect(_on_rex_health_changed)
	rex.died.connect(_on_rex_died)

	player.fired.connect(_on_player_fired)
	player.landed.connect(_on_player_landed)
	player.damaged.connect(_on_player_damaged)
	player.call_deferred("start_falling")

func _on_rex_health_changed(current, max):
	var pct = clamp(float(current) / float(max), 0.0, 1.0)
	var inner_max_w = health_bg.size.x - 12
	health_bar.size.x = int(inner_max_w * pct)

func _on_player_damaged(current, max):
	var pct = clamp(float(current) / float(max), 0.0, 1.0)
	var inner_max_w = $UI/PlayerHealthBG.size.x - 12
	player_health_bar.size.x = int(inner_max_w * pct)

func _on_rex_died():
	health_bar.color = Color(0.2, 0.9, 0.3)
	if audio_node and audio_node.has_node("SFX_Victory"):
		var sv = audio_node.get_node("SFX_Victory")
		if sv and sv.stream:
			sv.play()

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

# --- Helpers ---

func _make_tex(col: Color, w: int, h: int) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			img.set_pixel(x, y, col)
	var tex = ImageTexture.create_from_image(img)
	return tex

func _make_silence() -> AudioStreamWAV:
	# AudioStreamSample was renamed to AudioStreamWAV in Godot 4
	var sample = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	sample.stereo = false
	sample.loop_mode = AudioStreamWAV.LOOP_DISABLED
	sample.data = PackedByteArray()  # PoolByteArray renamed to PackedByteArray
	return sample

func _ensure_placeholders():
	# Prefer user-provided assets in res://assets/ (player.png, rex.png, background.png)
	var assets_dir = "res://assets/"
	var player_path = assets_dir + "player.png"
	var rex_path = assets_dir + "rex.png"
	var bg_path = assets_dir + "background.png"

	# Background
	if has_node("Background"):
		var bg = get_node("Background")
		if ResourceLoader.exists(bg_path):
			bg.texture = load(bg_path)
		# else leave background empty (procedural or editor background)

	# Player sprite: load user asset if present, otherwise procedural
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

	# Ransomware Rex sprite
	var rsprite: Sprite2D = null
	if rex.has_node("Sprite2D"):
		rsprite = rex.get_node("Sprite2D")
	else:
		rsprite = Sprite2D.new()
		rsprite.name = "Sprite2D"
		rex.add_child(rsprite)

	if ResourceLoader.exists(rex_path):
		rsprite.texture = load(rex_path)
	else:
		rsprite.texture = _make_tex(Color(0.6, 0.0, 0.6, 1), 160, 120)

	var an = get_node("Audio") if has_node("Audio") else null
	if an:
		if an.has_node("SFX_Land"):
			an.get_node("SFX_Land").stream = _make_silence()
		if an.has_node("SFX_Shoot"):
			an.get_node("SFX_Shoot").stream = _make_silence()
		if an.has_node("SFX_Victory"):
			an.get_node("SFX_Victory").stream = _make_silence()
