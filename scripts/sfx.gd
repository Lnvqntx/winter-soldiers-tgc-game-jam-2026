extends Node

# Procedural Sound & Music Engine for LENAL
# 100% self-contained, CC0, WebGL / HTML5 compatible.

var master_volume: float = 1.0
var music_volume: float = 0.75
var sfx_volume: float = 0.85
var mouse_sensitivity_setting: float = 0.003

var _player_pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer = null
var _current_music_track: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pre-generate core sound effects
	_streams["interact"] = _generate_interact_sound()
	_streams["chicken"] = _generate_chicken_sound()
	_streams["lantern"] = _generate_lantern_sound()
	_streams["note"] = _generate_note_sound()
	_streams["ending"] = _generate_ending_sound()
	_streams["footstep"] = _generate_footstep_sound()
	_streams["dramatic"] = _generate_dramatic_sound()
	_streams["jump"] = _generate_jump_sound()
	_streams["land"] = _generate_land_sound()
	_streams["ui_click"] = _generate_ui_click_sound()
	_streams["ui_hover"] = _generate_ui_hover_sound()
	_streams["objective"] = _generate_objective_sound()

	# Pre-generate ambient background music tracks
	_streams["music_menu"] = _generate_menu_music()
	_streams["music_village"] = _generate_village_music()
	_streams["music_cave"] = _generate_cave_music()

	# Create audio player pool for SFX
	for i in range(8):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_player_pool.append(p)

	# Dual music players for smooth cross-fading
	_music_player_a = AudioStreamPlayer.new()
	_music_player_b = AudioStreamPlayer.new()
	add_child(_music_player_a)
	add_child(_music_player_b)

func _get_free_player() -> AudioStreamPlayer:
	for p in _player_pool:
		if not p.playing:
			return p
	return _player_pool[0]

func play(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(sound_name):
		return
	var player = _get_free_player()
	player.stream = _streams[sound_name]
	player.pitch_scale = pitch_scale
	
	# Compute effective volume in dB
	var eff_linear = master_volume * sfx_volume
	var base_db = linear_to_db(max(0.001, eff_linear))
	player.volume_db = base_db + volume_db
	player.play()

# --- Public SFX triggers ---

func play_interact() -> void:
	play("interact", randf_range(0.95, 1.05), -2.0)

func play_chicken() -> void:
	play("chicken", randf_range(0.9, 1.15), 0.0)

func play_lantern() -> void:
	play("lantern", 1.0, 1.0)

func play_note() -> void:
	play("note", 1.0, 0.0)

func play_dramatic() -> void:
	play("dramatic", 1.0, 2.0)

func play_ending() -> void:
	play("ending", 1.0, 3.0)

func play_footstep() -> void:
	play("footstep", randf_range(0.85, 1.15), -14.0)

func play_jump() -> void:
	play("jump", randf_range(0.95, 1.05), -4.0)

func play_land() -> void:
	play("land", randf_range(0.9, 1.1), -5.0)

func play_ui_click() -> void:
	play("ui_click", randf_range(0.98, 1.05), -2.0)

func play_ui_hover() -> void:
	play("ui_hover", 1.0, -8.0)

func play_objective() -> void:
	play("objective", 1.0, 1.0)

# --- Music Management with Smooth Cross-fades ---

func play_music(track_name: String, fade_duration: float = 1.0) -> void:
	var key = "music_" + track_name if not track_name.begins_with("music_") else track_name
	if _current_music_track == key and _active_music_player and _active_music_player.playing:
		return
	if not _streams.has(key):
		return
		
	_current_music_track = key
	var next_player = _music_player_b if _active_music_player == _music_player_a else _music_player_a
	var prev_player = _active_music_player
	
	next_player.stream = _streams[key]
	var target_db = linear_to_db(max(0.001, master_volume * music_volume))
	next_player.volume_db = -60.0
	next_player.play()
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(next_player, "volume_db", target_db, fade_duration)
	if prev_player and prev_player.playing:
		tween.tween_property(prev_player, "volume_db", -60.0, fade_duration)
		tween.chain().tween_callback(prev_player.stop)
		
	_active_music_player = next_player

func stop_music(fade_duration: float = 0.8) -> void:
	_current_music_track = ""
	if _active_music_player and _active_music_player.playing:
		var p = _active_music_player
		var tween = create_tween()
		tween.tween_property(p, "volume_db", -60.0, fade_duration)
		tween.tween_callback(p.stop)
		_active_music_player = null

func update_volumes() -> void:
	if _active_music_player and _active_music_player.playing:
		var target_db = linear_to_db(max(0.001, master_volume * music_volume))
		_active_music_player.volume_db = target_db

func set_master_volume(linear_val: float) -> void:
	master_volume = clamp(linear_val, 0.0, 1.0)
	update_volumes()

func set_music_volume(linear_val: float) -> void:
	music_volume = clamp(linear_val, 0.0, 1.0)
	update_volumes()

func set_sfx_volume(linear_val: float) -> void:
	sfx_volume = clamp(linear_val, 0.0, 1.0)

# --- Procedural Audio Synthesizers (PCM 16-bit Mono, 22050 Hz) ---

func _create_wav(samples: PackedByteArray, sample_rate: int = 22050, loop_mode: int = AudioStreamWAV.LOOP_DISABLED) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	wav.loop_mode = loop_mode
	if loop_mode != AudioStreamWAV.LOOP_DISABLED:
		wav.loop_begin = 0
		wav.loop_end = samples.size() / 2
	return wav

func _generate_footstep_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.07
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = 1.0 - (float(i) / float(total_samples))
		env = env * env
		var freq = 120.0 * (1.0 - t * 8.0)
		var val = sin(t * freq * TAU) * 0.7 + (randf() * 2.0 - 1.0) * 0.3
		var s16 = int(clamp(val * env * 14000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
	
	return _create_wav(data, rate)

func _generate_jump_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.18
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = 1.0 - (float(i) / float(total_samples))
		# Pitch sweeps up from 180Hz to 420Hz (cheerful spring bounce)
		var freq = 180.0 + (t / duration) * 260.0
		var val = sin(t * freq * TAU) + 0.3 * sin(t * freq * 2.0 * TAU)
		var s16 = int(clamp(val * env * 16000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_land_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.12
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = exp(-t * 22.0)
		# Low thud (75Hz down to 40Hz)
		var freq = 75.0 - t * 250.0
		var val = sin(t * max(30.0, freq) * TAU) * 0.8 + (randf() * 2.0 - 1.0) * 0.2
		var s16 = int(clamp(val * env * 19000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_interact_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.16
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = 1.0 - (float(i) / float(total_samples))
		var freq = 587.33 if t < 0.07 else 880.0
		var val = sin(t * freq * TAU)
		var s16 = int(clamp(val * env * 18000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_ui_click_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.06
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = exp(-t * 50.0)
		var freq = 1200.0 - t * 8000.0
		var val = sin(t * max(200.0, freq) * TAU) + (randf() * 2.0 - 1.0) * 0.2
		var s16 = int(clamp(val * env * 22000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_ui_hover_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.04
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = exp(-t * 60.0)
		var val = sin(t * 880.0 * TAU)
		var s16 = int(clamp(val * env * 12000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_objective_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.45
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# Bright 3-note melodic fanfare (E5 -> G#5 -> B5)
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var step = int(t / 0.12)
		var freq = 659.25 # E5
		if step == 1: freq = 830.61 # G#5
		elif step >= 2: freq = 987.77 # B5
		
		var local_t = fmod(t, 0.12)
		var env = max(0.0, 1.0 - (local_t / 0.12))
		if step >= 2:
			env = max(0.0, 1.0 - (t - 0.24) / 0.21)
		var val = sin(t * freq * TAU) + 0.3 * sin(t * freq * 2.0 * TAU)
		var s16 = int(clamp(val * env * 18000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_chicken_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.22
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = sin((float(i) / float(total_samples)) * PI)
		var wobble = sin(t * 28.0 * TAU) * 120.0
		var freq = 600.0 + wobble + (100.0 if t < 0.1 else -150.0 * t)
		var val = sin(t * freq * TAU) + 0.3 * sin(t * freq * 2.0 * TAU)
		var s16 = int(clamp(val * env * 22000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_lantern_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.5
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var step = int(t / 0.12)
		var freq = 523.25
		if step == 1: freq = 659.25
		elif step == 2: freq = 783.99
		elif step >= 3: freq = 1046.50
		
		var local_t = fmod(t, 0.12)
		var env = max(0.0, 1.0 - (local_t / 0.12))
		if step == 3:
			env = max(0.0, 1.0 - (t - 0.36) / 0.14)
		var val = sin(t * freq * TAU) + 0.2 * sin(t * freq * 3.0 * TAU)
		var s16 = int(clamp(val * env * 20000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_note_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.4
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = exp(-t * 5.0)
		var val = 0.6 * sin(t * 330.0 * TAU) + 0.4 * sin(t * 335.0 * TAU) + 0.3 * sin(t * 660.0 * TAU)
		var s16 = int(clamp(val * env * 22000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_dramatic_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.8
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var env = min(1.0, t * 4.0) * (1.0 - (t / duration) * 0.5)
		var freq = 110.0
		var val = sin(t * freq * TAU) + 0.5 * sin(t * (freq * 1.5) * TAU) + 0.25 * sin(t * (freq * 2.0) * TAU)
		var s16 = int(clamp(val * env * 24000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

func _generate_ending_sound() -> AudioStreamWAV:
	var rate = 22050
	var duration = 1.6
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var note_idx = 0
		var note_start = 0.0
		var note_len = 0.32
		var freq = 349.23
		
		if t < 0.32:
			note_idx = 0
			note_start = 0.0
			freq = 349.23
		elif t < 0.64:
			note_idx = 1
			note_start = 0.32
			freq = 329.63
		elif t < 0.96:
			note_idx = 2
			note_start = 0.64
			freq = 311.13
		else:
			note_idx = 3
			note_start = 0.96
			note_len = 0.64
			var slide = (t - 0.96) / 0.64
			freq = 293.66 - slide * 45.0
			
		var note_t = t - note_start
		var env = 1.0 - (note_t / note_len) * 0.8
		var vibrato = sin(note_t * 18.0) * 8.0 if note_idx == 3 else 0.0
		var val = sin((t * (freq + vibrato)) * TAU) + 0.4 * sin((t * (freq + vibrato) * 2.0) * TAU) + 0.25 * sin((t * (freq + vibrato) * 3.0) * TAU)
		var s16 = int(clamp(val * env * 26000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)

# --- Procedural Looping Music Synthesizers ---

# Menu Music: Serene Indian folk melody in D Major with tanpura drone & sitar/flute arpeggio
func _generate_menu_music() -> AudioStreamWAV:
	var rate = 22050
	var duration = 4.8 # 4.8s seamless loop
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# Scale notes in D Raag Bhupali (D, E, F#, A, B, D5)
	var notes = [293.66, 329.63, 369.99, 440.0, 493.88, 587.33, 440.0, 369.99]
	var note_dur = duration / float(notes.size())
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		
		# 1. Warm drone base (D3 = 146.83Hz + A3 = 220Hz)
		var drone = 0.25 * sin(t * 146.83 * TAU) + 0.15 * sin(t * 220.0 * TAU)
		
		# 2. Plucked sitar/flute melody
		var n_idx = int(t / note_dur) % notes.size()
		var n_freq = notes[n_idx]
		var local_t = fmod(t, note_dur)
		var note_env = exp(-local_t * 5.0)
		var melody = (sin(t * n_freq * TAU) + 0.3 * sin(t * n_freq * 2.0 * TAU)) * note_env * 0.4
		
		var sample_val = drone + melody
		var s16 = int(clamp(sample_val * 16000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate, AudioStreamWAV.LOOP_FORWARD)

# Village Music: Light, playful, warm acoustic groove
func _generate_village_music() -> AudioStreamWAV:
	var rate = 22050
	var duration = 3.6 # 3.6s seamless loop
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	# Playful village melody notes (G Major / Bilawal: G, A, B, D, E, D, B, A)
	var notes = [392.0, 440.0, 493.88, 587.33, 659.25, 587.33, 493.88, 440.0, 392.0, 493.88, 587.33, 392.0]
	var note_dur = duration / float(notes.size())
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		
		# 1. Light rhythmic village pulse (every 0.45s)
		var pulse_t = fmod(t, 0.45)
		var pulse_env = exp(-pulse_t * 18.0)
		var rhythm = sin(t * 110.0 * TAU) * pulse_env * 0.2
		
		# 2. Cheerful melody
		var n_idx = int(t / note_dur) % notes.size()
		var n_freq = notes[n_idx]
		var local_t = fmod(t, note_dur)
		var note_env = max(0.0, 1.0 - (local_t / note_dur) * 0.85)
		var melody = (sin(t * n_freq * TAU) + 0.25 * sin(t * n_freq * 2.0 * TAU)) * note_env * 0.35
		
		# 3. Warm chord pad
		var chord = 0.12 * sin(t * 196.0 * TAU) + 0.1 * sin(t * 293.66 * TAU)
		
		var sample_val = rhythm + melody + chord
		var s16 = int(clamp(sample_val * 16000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate, AudioStreamWAV.LOOP_FORWARD)

# Cave Music: Deep echoing atmospheric mysterious drone
func _generate_cave_music() -> AudioStreamWAV:
	var rate = 22050
	var duration = 4.0 # 4.0s seamless loop
	var total_samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		
		# Deep subterranean sub-drone (65Hz C2 with slow 0.5Hz wobble)
		var sub = sin(t * (65.41 + sin(t * 0.5 * TAU) * 1.5) * TAU) * 0.35
		# Crystal resonance overtone (523Hz with slow beating)
		var crystal = (sin(t * 523.25 * TAU) + sin(t * 527.0 * TAU)) * 0.12
		# Airy breath / wind noise
		var wind = (randf() * 2.0 - 1.0) * 0.04
		
		var sample_val = sub + crystal + wind
		var s16 = int(clamp(sample_val * 16000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate, AudioStreamWAV.LOOP_FORWARD)
