extends Node2D
# Level 3: Worm King

@onready var player            = $Player
@onready var king              = $WormKing
@onready var enemies           = $Enemies
@onready var health_bg         = $UI/BossHealthBG
@onready var health_bar        = $UI/BossHealthBG/BossHealthBar
@onready var player_health_bg  = $UI/PlayerHealthBG
@onready var player_health_bar = $UI/PlayerHealthBG/PlayerHealthBar
@onready var ammo_bg           = $UI/AmmoBG
@onready var ammo_bar          = $UI/AmmoBG/AmmoBar
@onready var audio_node        = $Audio
@onready var projectiles       = $Projectiles

const AMMO_BAR_MAX_W = 118.0

func _ready():
	_ensure_placeholders()
	king.health_changed.connect(_on_king_health_changed)
	king.died.connect(_on_king_died)
	king.split.connect(_on_king_split)
	player.fired.connect(_on_player_fired)
	player.landed.connect(_on_player_landed)
	player.damaged.connect(_on_player_damaged)
	player.ammo_changed.connect(_on_ammo_changed)
	player.died.connect(_on_player_died)
	player.max_ammo = 9999
	player.ammo = 9999
	_on_ammo_changed(player.max_ammo, player.max_ammo)

	player.set_process(false)
	_show_level_intro(
		"WORM",
		Color(0.3, 0.9, 0.2),
		"A standalone, self-replicating type of malware that spreads across networks by exploiting vulnerabilities in systems, without needing human interaction to activate. They consume bandwidth and damage networks, often installing payloads that allow remote control of the machine.",
		func(): player.set_process(true); player.start_falling()
	)

func _on_king_health_changed(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	health_bar.size.x = (health_bg.size.x - 4) * pct

func _on_player_damaged(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	player_health_bar.size.x = (player_health_bg.size.x - 4) * pct

func _on_ammo_changed(current, max_val):
	var pct = clamp(float(current) / float(max_val), 0.0, 1.0)
	ammo_bar.size.x = AMMO_BAR_MAX_W * pct
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

	var dismissed = false
	var dismiss = func():
		if dismissed:
			return
		if not is_instance_valid(cl):
			return
		dismissed = true
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

func _on_king_died():
	health_bar.color = Color(0.2, 0.9, 0.3)
	_play_sfx("SFX_Victory")
	get_tree().create_timer(1.2).timeout.connect(_show_victory_screen)

func _on_king_split(pos, count):
	for i in range(count):
		var e = Node2D.new()
		e.set_script(load("res://WormMinion.gd"))
		e.position = pos + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		enemies.add_child(e)
	_play_sfx("SFX_Split")

func _on_player_fired(from_pos, direction):
	spawn_player_projectile(from_pos, direction, true)
	_play_sfx("SFX_Charge")

func _on_player_landed():
	_play_sfx("SFX_Land")

func spawn_player_projectile(from_pos, direction, charged = false):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.position = from_pos
	p.direction = direction
	p.owner_is_player = true
	p.damage = 28 if charged else 16
	projectiles.add_child(p)

func spawn_enemy_projectile(from_pos, direction):
	var p = Node2D.new()
	p.set_script(load("res://Projectile.gd"))
	p.position = from_pos
	p.direction = direction
	p.owner_is_player = false
	# Worm King fires slow engulf blobs — player must dodge out of them
	p.is_engulf = true
	p.speed = 48
	p.damage = 12   # per tick every 0.55 s
	p.lifetime = 4.0
	projectiles.add_child(p)

func _show_victory_screen():
	var cl = CanvasLayer.new()
	cl.layer = 10
	add_child(cl)

	var bg = ColorRect.new()
	bg.anchors_preset = 15
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.0, 0.0, 0.05, 0.92)
	cl.add_child(bg)

	var title = Label.new()
	title.text = "SYSTEM REBOOTED!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	title.position = Vector2(0, 18)
	title.size = Vector2(288, 24)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	cl.add_child(title)

	var fact = Label.new()
	fact.text = (
		"WORM FACT:\n" +
		"Worms self-replicate without\n" +
		"needing a host file. They spread\n" +
		"across networks and can clone\n" +
		"themselves endlessly.\n\n" +
		"Stay safe: keep your OS updated!"
	)
	fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fact.position = Vector2(20, 52)
	fact.size = Vector2(248, 80)
	fact.add_theme_font_size_override("font_size", 8)
	fact.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cl.add_child(fact)

	var portal = ColorRect.new()
	portal.color = Color(0.2, 0.8, 1.0, 0.0)
	portal.size = Vector2(30, 30)
	portal.position = Vector2(129, 115)
	cl.add_child(portal)

	var tween = create_tween()
	tween.tween_property(portal, "color:a", 0.85, 0.8)
	tween.tween_interval(1.0)

	var btn = Button.new()
	btn.text = "PLAY AGAIN"
	btn.position = Vector2(94, 142)
	btn.size = Vector2(100, 16)
	btn.add_theme_font_size_override("font_size", 8)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://intro_scene.tscn"))
	cl.add_child(btn)

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
	var bg = get_node_or_null("Background")
	if bg:
		if ResourceLoader.exists("res://assets/background3.png"):
			var tex = load("res://assets/background3.png")
			bg.texture = tex
			bg.scale = Vector2(288.0 / tex.get_width(), 162.0 / tex.get_height())
		else:
			bg.texture = _make_tex(Color(0.04, 0.04, 0.08), 288, 162)

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

	var ksprite: Sprite2D
	if king.has_node("Sprite2D"):
		ksprite = king.get_node("Sprite2D")
	else:
		ksprite = Sprite2D.new()
		ksprite.name = "Sprite2D"
		king.add_child(ksprite)
	if ResourceLoader.exists("res://assets/king.png"):
		ksprite.texture = load("res://assets/king.png")
		var sf_k = 50.0 / ksprite.texture.get_height()
		ksprite.scale = Vector2(sf_k, sf_k)
		king.has_custom_sprite = true

	for sfx_name in ["SFX_Charge", "SFX_Split", "SFX_Land", "SFX_Victory"]:
		if audio_node and audio_node.has_node(sfx_name):
			var n = audio_node.get_node(sfx_name)
			if n and not n.stream:
				n.stream = _make_silence()
