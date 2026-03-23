extends Node2D

# ---- Node refs ----
@onready var character     = $Character
@onready var tv_glow       = $TVGlow
@onready var tv_flicker    = $TVFlicker
@onready var glitch_overlay = $GlitchOverlay
@onready var fade_overlay  = $FadeOverlay

# TV center position — this is where the character gets sucked INTO
# Adjust X/Y to match the center of your TV in the background image
var tv_center = Vector2(576, 280)

# How long before the suck-in starts (seconds of idle animation)
var idle_time = 3.5

var elapsed = 0.0
var sequence_started = false
var flicker_timer = 0.0
var flicker_interval = 0.18
var flicker_on = false

func _ready():
	# Start the TV glow pulsing right away
	_start_tv_pulse()

func _process(delta):
	elapsed += delta

	# TV flicker animation while waiting
	if not sequence_started:
		flicker_timer += delta
		if flicker_timer >= flicker_interval:
			flicker_timer = 0.0
			flicker_on = !flicker_on
			# Randomly vary flicker brightness for realism
			var flicker_alpha = randf_range(0.03, 0.12) if flicker_on else 0.0
			tv_flicker.modulate.a = flicker_alpha
			# Also slightly pulse TV glow color
			var glow_alpha = randf_range(0.28, 0.45)
			tv_glow.modulate.a = glow_alpha

	# After idle time, start the suck-in sequence
	if elapsed >= idle_time and not sequence_started:
		sequence_started = true
		start_suck_in()

func _start_tv_pulse():
	# Continuously pulse the TV glow to simulate screen light
	var tween = create_tween().set_loops()
	tween.tween_property(tv_glow, "modulate:a", 0.45, 0.6)
	tween.tween_property(tv_glow, "modulate:a", 0.25, 0.6)

func start_suck_in():
	var tween = create_tween()

	# Step 1: Brief pause, then TV flicker goes crazy
	tween.tween_interval(0.2)
	tween.tween_callback(func():
		tv_flicker.color = Color(0.24, 0.96, 1.0, 0.0)  # blue-ish flicker
	)

	# Step 2: Rapid flicker burst (TV going haywire)
	for i in range(8):
		tween.tween_property(tv_flicker, "modulate:a", randf_range(0.5, 0.9), 0.04)
		tween.tween_property(tv_flicker, "modulate:a", 0.0, 0.04)

	# Step 3: Character spins and shrinks toward the TV center
	tween.tween_interval(0.1)
	tween.parallel().tween_property(
		character, "position", tv_center, 0.75
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(
		character, "scale", Vector2(0.0, 0.0), 0.75
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(
		character, "rotation_degrees", 720.0, 0.75
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Step 4: Big flash as he disappears
	tween.tween_property(glitch_overlay, "modulate:a", 1.0, 0.08)
	tween.tween_property(glitch_overlay, "modulate:a", 0.0, 0.08)
	tween.tween_property(glitch_overlay, "modulate:a", 0.85, 0.06)
	tween.tween_property(glitch_overlay, "modulate:a", 0.0, 0.06)

	# Step 5: Fade to black and load Level 1
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.6)
	tween.tween_callback(go_to_level_one)

func go_to_level_one():
	print("IntroScene: attempting to change to Level1")
	# sanity check: ensure file exists
	var path = "res://Level1.tscn"
	var exists = false
	if Engine.has_singleton("FileAccess"):
		exists = FileAccess.file_exists(path)
	else:
		exists = ResourceLoader.exists(path)
	if not exists:
		print("IntroScene: Level1.tscn not found at ", path)
		return
	var err = get_tree().change_scene_to_file(path)
	print("IntroScene: change_scene_to_file returned: ", err)
