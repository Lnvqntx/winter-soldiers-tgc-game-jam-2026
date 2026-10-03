@extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("--- Testing Procedural Music & Sound Synthesis ---")
	var sfx_script = load("res://scripts/sfx.gd")
	var sfx = sfx_script.new()
	root.add_child(sfx)
	await process_frame
	
	var expected_sounds = [
		"interact", "chicken", "lantern", "note", "dramatic", "ending", 
		"footstep", "jump", "land", "ui_click", "ui_hover", "objective",
		"music_menu", "music_village", "music_cave"
	]
	for snd in expected_sounds:
		print("Has stream: %-15s -> %s" % [snd, sfx._streams.has(snd)])
		assert(sfx._streams.has(snd), "Must have " + snd)
	
	sfx.play_jump()
	sfx.play_land()
	sfx.play_objective()
	sfx.play_music("menu", 0.1)
	assert(sfx._active_music_player != null and sfx._active_music_player.playing, "Music should be playing")
	sfx.stop_music(0.1)
	
	sfx.queue_free()
	print("ALL Procedural SFX & Music verified 100%!")
	quit(0)
