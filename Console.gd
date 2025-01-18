extends PopupPanel

func _process(delta):
	if Input.is_action_just_pressed("Console"):
		visible = !visible


func _on_line_edit_text_submitted(new_text):
	$Panel/VSplitContainer/Label.text += new_text + "\n"
	if "reset" in new_text:
		get_parent().resetAll()
	
	#replace text
	$Panel/VSplitContainer/LineEdit.text = ""
