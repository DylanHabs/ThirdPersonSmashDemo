extends CanvasLayer

@onready var body = $Mario/Armature/Skeleton3D/Body_001
var fileName = "Default.tres"
var imageData
@onready var hatSelector = $Mario/Armature/Skeleton3D/Body_001/HatSelector

func _ready():
	$Panel/TabContainer/Face/VBoxContainer/HatSlider.max_value = hatSelector.size - 1
	

func loadCharacter():
	var data = ResourceLoader.load("user://Characters/" + fileName)
	body.set("blend_shapes/Jaw", data.jaw)
	body.set("blend_shapes/Arms", data.arms)
	body.set("blend_shapes/Shoulders", data.shoulder)
	body.set("blend_shapes/Belly", data.belly)
	body.set("blend_shapes/Butt", data.butt)
	body.set("blend_shapes/Chest", data.chest)
	body.set("blend_shapes/Legs", data.legs)
	
	$Panel/TabContainer/Proportions/VBoxContainer/JawSlider.value = data.jaw
	$Panel/TabContainer/Proportions/VBoxContainer/ShoulderSlider.value = data.shoulder
	$Panel/TabContainer/Proportions/VBoxContainer/ArmsSlider2.value = data.arms
	$Panel/TabContainer/Proportions/VBoxContainer/BellySlider3.value = data.belly
	$Panel/TabContainer/Proportions/VBoxContainer/ButtSlider4.value = data.butt
	$Panel/TabContainer/Proportions/VBoxContainer/LegsSlider5.value = data.legs
	$Panel/TabContainer/Proportions/VBoxContainer/BoobsSlider6.value = data.chest
	$Panel/TabContainer/Colors/VBoxContainer/SkinColor.color = data.skin
	$Panel/TabContainer/Colors/VBoxContainer/ShirtColor.color = data.shirt
	$Panel/TabContainer/Colors/VBoxContainer/GloveColor.color = data.gloves
	$Panel/TabContainer/Colors/VBoxContainer/PantsColor.color = data.pants
	$Panel/TabContainer/Colors/VBoxContainer/BootsColor.color = data.boots
	$Panel/TabContainer/Face/VBoxContainer/HatSlider.value = data.hatIndex
	$Panel/TabContainer/Proportions/VBoxContainer/SizeSlider2.value = data.size
	
	changeColor(data.skin, 0)
	changeColor(data.shirt, 1)
	changeColor(data.gloves, 3)
	changeColor(data.pants, 2)
	changeColor(data.boots, 4)
	
	hatSelector.setHat(data.hatIndex)
	var material = body.get_active_material(5)
	if data.faceImg:
		var img = Image.new()
		img = Image.create_from_data(data.faceImg["width"], data.faceImg["height"], data.faceImg["mipmaps"], data.faceImg["format"], data.faceImg["data"])
		imageData = img.data
		imageData["format"] = img.get_format()
		material.albedo_color = Color.WHITE
		var texture = ImageTexture.new()
		texture.set_image(img)
		material.albedo_texture = texture
	else:
		material.albedo_color = Color.TRANSPARENT
	body.set_surface_override_material(5, material)

func saveCharacter():
	var dataToSave = load("user://Characters/Default.tres").duplicate()
	dataToSave.size = $Panel/TabContainer/Proportions/VBoxContainer/SizeSlider2.value
	dataToSave.jaw = body.get("blend_shapes/Jaw")
	dataToSave.arms = body.get("blend_shapes/Arms")
	dataToSave.shoulder = body.get("blend_shapes/Shoulders")
	dataToSave.belly = body.get("blend_shapes/Belly")
	dataToSave.butt = body.get("blend_shapes/Butt")
	dataToSave.chest = body.get("blend_shapes/Chest")
	dataToSave.legs = body.get("blend_shapes/Legs")
	
	dataToSave.skin = getColor(0)
	dataToSave.shirt = getColor(1)
	dataToSave.gloves = getColor(3)
	dataToSave.pants = getColor(2)
	dataToSave.boots = getColor(4)
	dataToSave.hatIndex = hatSelector.lastName
	
	if body.get_active_material(5).albedo_color.a == 1.0:
		if imageData:
			dataToSave.faceImg = imageData
	else:
		dataToSave.faceImg.clear()
	
	ResourceSaver.save(dataToSave, "user://Characters/" + fileName)
	self.visible = false

func getColor(index):
	return body.get_active_material(index).albedo_color
func changeColor(color, index):
	var material = body.get_active_material(index)
	material.albedo_color = color
	body.set_surface_override_material(index, material)

func _on_jaw_slider_value_changed(value):
	body.set("blend_shapes/Jaw", value)

func _on_arms_slider_2_value_changed(value):
	body.set("blend_shapes/Arms", value)

func _on_shoulder_slider_value_changed(value):
	body.set("blend_shapes/Shoulders", value)

func _on_belly_slider_3_value_changed(value):
	body.set("blend_shapes/Belly", value)

func _on_butt_slider_4_value_changed(value):
	body.set("blend_shapes/Butt", value)

func _on_legs_slider_5_value_changed(value):
	body.set("blend_shapes/Legs", value)

func _on_boobs_slider_6_value_changed(value):
	body.set("blend_shapes/Chest", value)

func _on_skin_color_color_changed(color):
	changeColor(color, 0)

func _on_shirt_color_color_changed(color):
	changeColor(color, 1)

func _on_glove_color_color_changed(color):
	changeColor(color, 3)

func _on_pants_color_color_changed(color):
	changeColor(color, 2)

func _on_boots_color_color_changed(color):
	changeColor(color, 4)

func _on_h_slider_value_changed(value):
	body.rotation_degrees = Vector3(0, value, 0)

func _on_hat_slider_value_changed(value):
	hatSelector.setHat(value)

func _on_size_slider_2_value_changed(value):
	pass
	#body.scale = Vector3(value, value, value)

func _on_button_button_up():
	var path = $Panel/TabContainer/Face/VBoxContainer/FilePath.text
	var image = Image.new()
	image.load(path)
	imageData = image.data
	imageData["format"] = image.get_format()
	#imageFormat = image.get_format()
	var imgTexture = ImageTexture.new()
	imgTexture.set_image(image)
	$Panel/TabContainer/Face/VBoxContainer/TextureRect.texture = imgTexture
	
	var material = body.get_active_material(5)
	material.albedo_color = Color.WHITE
	material.albedo_texture = imgTexture
	body.set_surface_override_material(5, material)

func _on_button_2_button_up():
	var material = body.get_active_material(5)
	material.albedo_color = Color.TRANSPARENT
	body.set_surface_override_material(5, material)
