extends Node3D

var hats = []
var size = 0
var lastName = -1

func _ready():
	for c in get_children():
		hats.push_back(c)
		c.visible = false
	size = len(hats)

func setHat(index):
	if lastName != -1:
		hats[lastName].visible = false
	
	if index != -1:	
		hats[index].visible = true	
	
	lastName = index
