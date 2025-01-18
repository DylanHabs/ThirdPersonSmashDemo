extends Node3D

func _ready():
	setSpectate(false)

func setSpectate (spec):
	if spec:
		$Player.set_process(false)
		$Player.visible = false
	else:
		$Spectate.set_process(false)
		$Spectate.visible = false
