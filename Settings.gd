extends CanvasLayer

func _enter_tree():
	if is_multiplayer_authority():
		findCharacters()

func _on_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	pass # Replace with function body.

func findCharacters():
	var files = DirAccess.get_files_at("user://Characters/")
	for f in files:
		if f.get_extension() == "tres":
			$VBoxContainer/ItemList.add_item(f.get_basename())
