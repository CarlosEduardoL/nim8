extends AudioStreamPlayer

var sound = preload("res://sound/sound.wav")

func _process(_delta):
	if Emulator.sound && !self.is_playing():
		stream = sound
		play()
	else:
		stop()
