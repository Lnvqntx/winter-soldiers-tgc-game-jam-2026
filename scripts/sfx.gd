extends Node

# Procedural Sound Effect Generator & Player for LENAL
# Creates self-contained 8-bit / arcade audio without external assets

var _player_pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}

func _ready() -> void:
	# Pre-generate streams
	_streams["interact"] = _generate_interact_sound()
	_streams["chicken"] = _generate_chicken_sound()
	_streams["lantern"] = _generate_lantern_sound()
	_streams["note"] = _generate_note_sound()
	_streams["ending"] = _generate_ending_sound()
	_streams["footstep"] = _generate_footstep_sound()
	_streams["dramatic"] = _generate_dramatic_sound()

	# Create audio player pool
	for i in range(6):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_player_pool.append(p)

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
	player.volume_db = volume_db
	player.play()

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
	play("footstep", randf_range(0.85, 1.15), -12.0)

# --- Procedural Audio Synthesizers (PCM 16-bit Mono, 22050 Hz) ---

func _create_wav(samples: PackedByteArray, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
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
		# Low frequency pop + slight noise for gravel/dirt
		var freq = 120.0 * (1.0 - t * 8.0)
		var val = sin(t * freq * TAU) * 0.7 + (randf() * 2.0 - 1.0) * 0.3
		var s16 = int(clamp(val * env * 14000.0, -32767.0, 32767.0))
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
		# Two-tone cheerful blip (587Hz D5 -> 880Hz A5)
		var freq = 587.33 if t < 0.07 else 880.0
		var val = sin(t * freq * TAU)
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
		# Wobbly FM chicken squawk: 450Hz carrier modulated with 25Hz wobble
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
	
	# Rising 4-tone triumphant sparkle: C5 -> E5 -> G5 -> C6
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
		# Spooky bell tone with detuned sine waves
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
		# Deep dramatic low cello/brass pulse
		var freq = 110.0 # A2
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
	
	# Comedic "Wah-Wah-Wah-Waaaaah" trombone meme
	# 4 descending notes: F4 (349Hz), E4 (329Hz), Eb4 (311Hz), D4 with pitch bend down to C# (293 -> 260Hz)
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
			# Slide down
			var slide = (t - 0.96) / 0.64
			freq = 293.66 - slide * 45.0
			
		var note_t = t - note_start
		var env = 1.0 - (note_t / note_len) * 0.8
		# Add buzzy brass overtones and vibrato
		var vibrato = sin(note_t * 18.0) * 8.0 if note_idx == 3 else 0.0
		var val = sin((t * (freq + vibrato)) * TAU) + 0.4 * sin((t * (freq + vibrato) * 2.0) * TAU) + 0.25 * sin((t * (freq + vibrato) * 3.0) * TAU)
		var s16 = int(clamp(val * env * 26000.0, -32767.0, 32767.0))
		data.encode_s16(i * 2, s16)
		
	return _create_wav(data, rate)
