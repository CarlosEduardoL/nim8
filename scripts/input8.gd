extends Node2D

# Map the Chip-8 Keyboard to an usual keyboard
const KeyMap = [KEY_1, KEY_2, KEY_3, KEY_4,
				KEY_Q, KEY_W, KEY_E, KEY_R,
				KEY_A, KEY_S, KEY_D, KEY_F,
				KEY_Z, KEY_X, KEY_C, KEY_V,]

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventKey:
		for i in range(KeyMap.size()):
			if event.pressed && event.scancode == KeyMap[i]:
				Emulator._on_key_changed(i, true)
			if not event.pressed && event.scancode == KeyMap[i]:
				Emulator._on_key_changed(i, false)
