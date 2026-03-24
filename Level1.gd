extends Node2D

# Level 1: Ransomware Rex
@onready var player           = $Player
@onready var rex              = $RansomwareRex
@onready var health_bg        = $UI/BossHealthBG
@onready var health_bar       = $UI/BossHealthBG/BossHealthBar
@onready var player_health_bg = $UI/PlayerHealthBG
@onready var player_health_bar = $UI/PlayerHealthBG/PlayerHealthBar
@onready var ammo_bg          = $UI/AmmoBG
@onready var ammo_bar         = $UI/AmmoBG/AmmoBar
@onready var projectiles      = $Projectiles
@onready var audio_node       = $Audio

const AMMO_BAR_MAX_W = 118.0

func _ready():
	_ensure_placeholders()

	rex.health_changed.connect(_on_rex_health_changed)
	rex.died.connect(_on_rex_died)

	player.fired.connect(_on_player_fired)
	player.landed.connect(_on_player_landed)
	player.damaged.connect(_on_player_damaged)
	player.ammo_changed.connect(_on_ammo_changed)
	player.died.connect(_on_player_died)
	_on_ammo_changed(player.max_ammo, player.max_ammo)

	# Freeze player until intro
	player.set_process(false)
	_show_level_intro(
		"RANSOMWARE",
		Color(0.9, 0.2, 0.1),
		"This malware locks a user's computer or encrypts files, making them inaccessible, and demands a ransom payment to restore access.",
		func(): player.set_process(true); player.start_falling()
	)

func _on_rex_health_changed(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	health_bar.size.x = (health_bg.size.x - 4) * pct

func _on_player_damaged(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	player_health_bar.size.x = (player_health_bg.size.x - 4) * pct

func _on_ammo_changed(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	ammo_bar.size.x = AMMO_BAR_MAX_W * pct
	# Ammo color
	if pct > 0.5:
		ammo_bar.color = Color(0.2, 0.6, 1.0)
	elif pct > 0.2:
		ammo_bar.color = Color(1.0, 0.7, 0.1)
	else:
		ammo_bar.color = Color(0.9, 0.1, 0.1)

func _show_level_intro(virus_name: String, accent: Color, description: String, callback: Callable):
	var cl = CanvasLayer.new()
	cl.layer = 20
	add_child(cl)

	# UI size (288x162 game pixels)
	var bg = ColorRect.new()
	bg.offset_left = 0; bg.offset_top = 0; bg.offset_right = 288; bg.offset_bottom = 162
	bg.color = Color(0.02, 0.02, 0.08, 0.95)
	cl.add_child(bg)

	var badge = ColorRect.new()
	badge.offset_left = 0; badge.offset_top = 24; badge.offset_right = 288; badge.offset_bottom = 26
	badge.color = accent
	cl.add_child(badge)

	var title = Label.new()
	title.text = "VIRUS ALERT: " + virus_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = 0; title.offset_top = 6; title.offset_right = 288; title.offset_bottom = 22
	title.add_theme_font_size_override("font_size", 9)
	title.add_theme_color_override("font_color", accent)
	cl.add_child(title)

	var desc = Label.new()
	desc.text = description
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.offset_left = 12; desc.offset_top = 30; desc.offset_right = 276; desc.offset_bottom = 136
	desc.add_theme_font_size_override("font_size", 7)
	desc.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cl.add_child(desc)

	var btn = Button.new()
	btn.text = "TAP TO FIGHT"
	btn.offset_left = 84; btn.offset_top = 140; btn.offset_right = 204; btn.offset_bottom = 154
	btn.add_theme_font_size_override("font_size", 7)
	cl.add_child(btn)

	var dismiss = func():
		if not is_instance_valid(cl):
			return
		var tw = create_tween()
		tw.tween_property(cl, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func():
			if is_instance_valid(cl):
				cl.queue_free()
			callback.call()
		)

	btn.pressed.connect(dismiss)
	btn.grab_focus()
	get_tree().create_timer(6.0).timeout.connect(dismiss)

func _on_player_died():
	_show_death_screen()

func _show_death_screen():
	var cl = CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	var overlay = ColorRect.new()
	overlay.anchors_preset = 15
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0.5, 0.0, 0.0, 0.0)
	cl.add_child(overlay)
	var lbl = Label.new()
	lbl.text = "YOU DIED"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = 15
	lbl.anchor_right = 1.0
	lbl.anchor_bottom = 1.0
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	cl.add_child(lbl)
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.75, 0.4)
	tween.tween_interval(1.2)
	tween.tween_callback(func(): get_tree().reload_current_scene())

func _on_rex_died():
	health_bar.color = Color(0.2, 0.9, 0.3)
	_play_sfx("SFX_Victory")
	call_deferred("_go_to_level_two")

func _on_player_fired(from_pos, direction):
	spawn_player_projectile(from_pos, direction)
	_play_sfx("SFX_Shoot")

func _on_player_landed():
	_play_sfx("SFX_Land")

func spawn_player_projectile(from_pos, direction):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.position = from_pos
	p.direction = direction
	p.owner_is_player = true
	p.damage = 30
	projectiles.add_child(p)

func spawn_enemy_projectile(from_pos, direction):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.position = from_pos
	p.direction = direction
	p.owner_is_player = false
	projectiles.add_child(p)

func _go_to_level_two():
	get_tree().change_scene_to_file("res://Level2.tscn")

func _play_sfx(sfx_name: String):
	if audio_node and audio_node.has_node(sfx_name):
		var sfx = audio_node.get_node(sfx_name)
		if sfx and sfx.stream:
			sfx.play()

func _make_tex(col: Color, w: int, h: int) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(col)
	return ImageTexture.create_from_image(img)

func _make_silence() -> AudioStreamWAV:
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 22050
	s.stereo = false
	s.loop_mode = AudioStreamWAV.LOOP_DISABLED
	s.data = PackedByteArray()
	return s

func _ensure_placeholders():
	# Background: try assets/background.png, else solid dark-green
	var bg = get_node_or_null("Background")
	if bg:
		if ResourceLoader.exists("res://assets/background.png"):
			var tex = load("res://assets/background.png")
			bg.texture = tex
			bg.scale = Vector2(288.0 / tex.get_width(), 162.0 / tex.get_height())
		else:
			bg.texture = _make_tex(Color(0.1, 0.18, 0.08), 288, 162)

	# Player sprite
	var psprite: Sprite2D
	if player.has_node("Sprite2D"):
		psprite = player.get_node("Sprite2D")
	else:
		psprite = Sprite2D.new()
		psprite.name = "Sprite2D"
		player.add_child(psprite)
	if ResourceLoader.exists("res://assets/TSA.MC.WaterGunPNG.png"):
		psprite.texture = load("res://assets/TSA.MC.WaterGunPNG.png")
		var sf_p = 40.0 / psprite.texture.get_height()
		psprite.scale = Vector2(sf_p, sf_p)
		player.has_custom_sprite = true

	# Rex sprite
	var rsprite: Sprite2D
	if rex.has_node("Sprite2D"):
		rsprite = rex.get_node("Sprite2D")
	else:
		rsprite = Sprite2D.new()
		rsprite.name = "Sprite2D"
		rex.add_child(rsprite)
	if ResourceLoader.exists("res://assets/rex.png"):
		rsprite.texture = load("res://assets/rex.png")
		var sf_r = 50.0 / rsprite.texture.get_height()
		rsprite.scale = Vector2(sf_r, sf_r)
		rex.has_custom_sprite = true

	# Audio placeholders
	for sfx_name in ["SFX_Land", "SFX_Shoot", "SFX_Victory"]:
		if audio_node and audio_node.has_node(sfx_name):
			var n = audio_node.get_node(sfx_name)
			if n and not n.stream:
				n.stream = _make_silence()
