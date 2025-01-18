extends CharacterBody3D
#misc vars
@export var meshInst:MeshInstance3D
@export var slideCurve:Curve
var lives = 3
var health = 0
var userName = ""
@export var hitCols: Array[Area3D]
var curMove
const ANIM_SPEED = 2
var animSync = 0.0
var syncGround = 1
#Movement variables
var size = 1.0
const MAX_SPEED = 6.5
const MAX_SPEED_AIR = 5.0
const GROUND_ACCEL = 45
const AIR_ACCEL = 20
const FRICTION = 5
const JUMP_VELOCITY = 6
const GRAVITY = 10
const GRAVITY2 = 30
const MINY = -10
var doubleJumped = false
@onready var slideTimer = $slideTimer
#Camera Variables
@export var sensitivity = 0.9
@export var yRotationLimit = 90
@onready var camPivot = $Campivot
@onready var cam = $Campivot/SpringArm3D/Camera3D
#Inputs
var doingMove = false
var startup = false
var inputs: Array[InputQ]
const INPUTQ_LENGTH = 6

func _enter_tree():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_multiplayer_authority(name.to_int())
	if is_multiplayer_authority():
		$HealthLabel.hide()
	else:
		$Label.hide()
	for c in hitCols:
		c.monitoring = false
		
@rpc("any_peer", "call_local", "reliable")
func requestCharData():
	if is_multiplayer_authority():
		var newResource = ResourceLoader.load("user://Characters/" + get_parent().get_node("CharacterCreation").fileName)
		rpc("setCustomCharacter", inst_to_dict(newResource))

func _ready():
	$"Esc Menu".visible = false
	slideTimer.wait_time = slideCurve.get_point_position(slideCurve.point_count - 1).x
	cam.current = is_multiplayer_authority()
	userName = get_parent().get_node("MainMenu/VBoxContainer/Name/NameText").text
	setHealthLabel()

func setHealthLabel():
	var livesText = ""
	for i in range(lives):
		livesText += "|"
	$HealthLabel.text = str(userName, " ", livesText, "\n", health, "%")
	$Label.text = $HealthLabel.text

func _input(event):
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and not $"Esc Menu".visible:
		rotate_y(deg_to_rad(-event.relative.x  * sensitivity))
		camPivot.rotation_degrees.x += -event.relative.y  * sensitivity
		camPivot.rotation_degrees.x = clamp(camPivot.rotation_degrees.x, -yRotationLimit, yRotationLimit)
		
func _process(delta):
	if is_multiplayer_authority(): 
		if doingMove:
			animSync = $Mario/AnimationPlayer.current_animation_position
		if Input.is_action_just_pressed("ui_cancel"):
			$"Esc Menu".visible = !$"Esc Menu".visible
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if $"Esc Menu".visible else Input.MOUSE_MODE_CAPTURED
		if $"Esc Menu".visible or lives <= 0:
			return
		if Input.is_action_just_pressed("Fire"):
			#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			var button = load("res://example_in.tres").duplicate()
			button.type = "Fire1"
			inputs.push_back(button)
		if Input.is_action_just_pressed("Fire2"):
			var button = load("res://example_in.tres").duplicate()
			button.type = "Fire2"
			inputs.push_back(button)
		if Input.is_action_just_pressed("forward"):
			var button = load("res://example_in.tres").duplicate()
			button.type = "ForwardDown"
			inputs.push_back(button)
			button = load("res://example_in.tres").duplicate()
			button.type = "ForwardPressed"
			inputs.push_back(button)
		if Input.is_action_just_pressed("dash") and slideTimer.is_stopped():
			slideTimer.start()
			rpc("playDash")
		checkInputs()
	else:
		$Mario/AnimationPlayer.seek(animSync)

func checkInputs():
	#check if move can be done
	var input = ""
	for i in range(inputs.size() -1, -1, -1):
		input += inputs[i].type + " "
		if inputs[i].age >= INPUTQ_LENGTH:
			if inputs[i].type != "ForwardPressed" or not Input.is_action_pressed("forward"):
				#print("RM " + inputs[i].type) 
				inputs.remove_at(i)
		else:
			inputs[i].age += 1
	if not doingMove and slideTimer.is_stopped():
		if "Fire1" in input:
			if "ForwardDown" in input:
				doMove(preload("res://Moves/Smash.tres"))
			elif "ForwardPressed" in input:
				doMove(preload("res://Moves/Kick.tres"))
			else:
				doMove(preload("res://Moves/Jab.tres"))
		elif "Fire2" in input:
			doMove(preload("res://Moves/Fireball.tres"))

func doMove(move):
	if curMove:
		hitCols[curMove.collider].monitoring = false
	doingMove = true
	curMove = move
	rpc("playMove", move.sound.get_path())
	$AnimationTree.active = false    
	$Mario/AnimationPlayer.stop()
	$Mario/AnimationPlayer.play(move.attackName)
	$MoveTimer.start((move.startup + move.active + move.end) / 60.0)
	$StartupTimer.start(move.startup / 60.0)
	$ActiveTimer.start((move.startup + move.active) / 60.0)

func _physics_process(delta):
	if is_multiplayer_authority():
		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		var direction = Vector3.ZERO
		if not doingMove and $AnimationTree.get("parameters/HurtShot/active") != true and not $"Esc Menu".visible:
			direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if is_on_floor():
			velocity = accelerate(direction, delta, GROUND_ACCEL, MAX_SPEED)
			#Apply friction
			var speed = velocity.length()
			if speed != 0:
				var drop = speed * FRICTION * delta
				velocity *= max(speed - drop, 0) / speed
			# Handle Jump.
			doubleJumped = false
			if Input.is_action_pressed("jump"):
				jump()
		else:
			velocity = accelerate(direction, delta, AIR_ACCEL, MAX_SPEED_AIR)
			if Input.is_action_just_pressed("jump") and not doubleJumped:
				doubleJumped = true
				jump()
			if not Input.is_action_pressed("fastFall"):
				velocity.y -= GRAVITY * delta
			else:
				velocity.y -= GRAVITY2 * delta
			if global_position.y <= MINY: #DIE
				die()
		syncGround = (1 if is_on_floor() else 0) * (1 if slideTimer.is_stopped() else 0.01)
		move_and_slide()
		
	#Visuals
	var global_to_local = global_transform.affine_inverse()
	var tempV = global_to_local * (velocity / MAX_SPEED) - global_to_local * Vector3.ZERO
	$AnimationTree.set("parameters/WalkBlend/blend_position", Vector2(tempV.x, -tempV.z))
	$AnimationTree.set("parameters/TimeScale/scale", velocity.length() / MAX_SPEED * ANIM_SPEED * syncGround)

func die():
	velocity = Vector3.ZERO
	health = 0
	lives -= 1
	setHealthLabel()
	global_position = get_parent().get_node("SpawnPoint").global_position
	if lives <= 0:
		meshInst.transparency = 0.75
func jump():
	rpc("playJump")
	velocity.y = JUMP_VELOCITY
	
func accelerate(dir, delta, accel_type, max_velocity):
	var proj_vel = velocity.dot(dir)
	var slide_modifier = slideCurve.sample(slideTimer.wait_time - slideTimer.time_left)
	var accel_vel = accel_type * delta * slide_modifier
	
	if (proj_vel + accel_vel > max_velocity * slide_modifier / ((size + 1) / 2)):
		accel_vel = max_velocity - proj_vel
	
	return velocity + (dir * accel_vel)


func _on_move_timer_timeout():
	$AnimationTree.active = true  
	doingMove = false

func bodyEntered(body):
	if body != self and startup:
		startup = false
		body.rpc("playHurt", curMove.impact.get_path())
		body.rpc("hurtRPC", curMove.damage, curMove.knockback, global_position.direction_to(body.global_position) + Vector3(0, 0.5, 0))

@rpc ("any_peer", "call_local")
func playMove (sound):
	$MoveSound.stream = load(sound)
	$MoveSound.play()

@rpc ("any_peer", "call_local")
func playHurt (sound):
	$ImpactSound.stream = load(sound)
	$ImpactSound.play()

@rpc ("any_peer", "call_local")
func playDash ():
	$Dash.play()

@rpc ("any_peer", "call_local")
func playJump ():
	$Jump.play()

@rpc ("any_peer", "call_local")
func hurtRPC(dmg, knockBack, dir):
	dir = dir.normalized()
	health += dmg
	velocity += ((knockBack * health) / 20 / size) * dir
	$HurtSound.play()
	setHealthLabel()
	$AnimationTree.active = true
	$AnimationTree.set("parameters/HurtShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_startup_timer_timeout():
	startup = true
	hitCols[curMove.collider].monitoring = true
	if curMove.proj:
		get_parent().rpc("makeFire", -get_global_transform().basis.z, hitCols[curMove.collider].global_position, name)
	
func _on_active_timer_timeout():
	startup = false
	hitCols[curMove.collider].monitoring = false
	
@rpc("any_peer", "call_local", "reliable")
func setSpawnPos(pos):
	global_position = pos

@rpc("any_peer", "call_local", "reliable")
func setCustomCharacter(dict):
	var data = dict_to_inst(dict)
	size = data.size
	scale = Vector3(data.size, data.size, data.size)
	meshInst.set("blend_shapes/Jaw", data.jaw)
	meshInst.set("blend_shapes/Arms", data.arms)
	meshInst.set("blend_shapes/Shoulders", data.shoulder)
	meshInst.set("blend_shapes/Belly", data.belly)
	meshInst.set("blend_shapes/Butt", data.butt)
	meshInst.set("blend_shapes/Chest", data.chest)
	meshInst.set("blend_shapes/Legs", data.legs)
	changeColor(data.skin, 0)
	changeColor(data.shirt, 1)
	changeColor(data.gloves, 3)
	changeColor(data.pants, 2)
	changeColor(data.boots, 4)
	$Mario/Armature/Skeleton3D/BoneAttachment3D/HatSelector.setHat(data.hatIndex)
	var material = meshInst.get_active_material(5)
	if data.faceImg:
		var img = Image.new()
		img = Image.create_from_data(data.faceImg["width"], data.faceImg["height"], data.faceImg["mipmaps"], data.faceImg["format"], data.faceImg["data"])
		material.albedo_color = Color.WHITE
		var texture = ImageTexture.new()
		texture.set_image(img)
		material.albedo_texture = texture
	else:
		material.albedo_color = Color.TRANSPARENT
	meshInst.set_surface_override_material(5, material)

func changeColor(color, index):
	var material = meshInst.get_active_material(index)
	material.albedo_color = color
	meshInst.set_surface_override_material(index, material)

func _on_item_list_item_selected(index):
	var newResource = ResourceLoader.load("user://Characters/" + $"Esc Menu/VBoxContainer/ItemList".get_item_text(index) + ".tres")
	get_parent().get_node("CharacterCreation").fileName =  $"Esc Menu/VBoxContainer/ItemList".get_item_text(index) + ".tres"
	rpc("setCustomCharacter", inst_to_dict(newResource))
	$"Esc Menu".visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
@rpc("any_peer", "call_local", "reliable")
func reset():
	health = 0
	meshInst.transparency = 0
	lives = 3
	setHealthLabel()
