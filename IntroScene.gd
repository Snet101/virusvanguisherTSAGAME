extends Node2D

# ---- Node refs ----
@onready var character      = $Character
@onready var tv_glow        = $TVGlow
@onready var tv_flicker     = $TVFlicker
@onready var glitch_overlay = $GlitchOverlay
@onready var fade_overlay   = $FadeOverlay
@onready var speech_bubble  = $SpeechBubble

# Monitor screen center in 288x162 space
var tv_center = Vector2(120, 45)

var idle_time = 3.5
var elapsed = 0.0
var sequence_started = false
var flicker_timer = 0.0
var flicker_interval = 0.18
var flicker_on = false

func _ready():
	_start_tv_pulse()

func _process(delta):
	elapsed += delta

	if not sequence_started:
		flicker_timer += delta
		if flicker_timer >= flicker_interval:
			flicker_timer = 0.0
			flicker_on = !flicker_on
			var flicker_alpha = randf_range(0.03, 0.12) if flicker_on else 0.0
			tv_flicker.modulate.a = flicker_alpha
			var glow_alpha = randf_range(0.28, 0.45)
			tv_glow.modulate.a = glow_alpha

	if elapsed >= idle_time and not sequence_started:
		sequence_started = true
		start_suck_in()

func _start_tv_pulse():
	var tween = create_tween().set_loops()
	tween.tween_property(tv_glow, "modulate:a", 0.6, 0.5)
	tween.tween_property(tv_glow, "modulate:a", 0.25, 0.5)

func start_suck_in():
	var tween = create_tween()

	# Hide speech bubble
	tween.tween_property(speech_bubble, "modulate:a", 0.0, 0.3)

	# Brief pause, then TV flicker goes haywire
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		tv_flicker.color = Color(0.24, 0.96, 1.0, 0.0)
	)

	# Rapid flicker burst
	for i in range(8):
		tween.tween_property(tv_flicker, "modulate:a", randf_range(0.5, 0.9), 0.04)
		tween.tween_property(tv_flicker, "modulate:a", 0.0, 0.04)

	# Character spins and shrinks into the TV
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

	# Flash as he disappears
	tween.tween_property(glitch_overlay, "modulate:a", 1.0, 0.08)
	tween.tween_property(glitch_overlay, "modulate:a", 0.0, 0.08)
	tween.tween_property(glitch_overlay, "modulate:a", 0.85, 0.06)
	tween.tween_property(glitch_overlay, "modulate:a", 0.0, 0.06)

	# Fade to black and load Level 1
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.6)
	tween.tween_callback(go_to_level_one)

func go_to_level_one():
	get_tree().change_scene_to_file("res://Level1.tscn")
