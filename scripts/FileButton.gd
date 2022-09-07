extends MenuButton

# Called when the node enters the scene tree for the first time.
func _ready():
	get_popup().add_item("Load ROM")
	if get_popup().connect("id_pressed", self, "_on_item_pressed") != 0:
		printerr("Cannot Conect with the pop up buttons")

func _on_item_pressed(id):
	if id == 0:
		$FileDialog.popup()


func _on_FileDialog_file_selected(path):
	Emulator._load_rom(path)
