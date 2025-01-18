extends Node3D

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene
@export var projectile : PackedScene
var players = {}
var pojectiles = []
@export var defaultCharacters: Array[Resource]

func _ready():
	var dirExi = DirAccess.open("user://") 
	if not dirExi.dir_exists ("user://Characters/"):
		dirExi.make_dir("user://Characters/")
	for p in defaultCharacters:
		var path = p.resource_path.replace("res://", "user://")
		#print(path)
		ResourceSaver.save(p, path)
	findCharacters()
	$CharacterCreation.loadCharacter()

func findCharacters():
	var files = DirAccess.get_files_at("user://Characters/")
	for f in files:
		if f.get_extension() == "tres":
			$MainMenu/VBoxContainer/ItemList.add_item(f.get_basename())

func _on_connect_pressed():
	peer.create_client($MainMenu/VBoxContainer/IPBOX/LineEdit.text, 1027)
	multiplayer.multiplayer_peer = peer
	$MainMenu.hide()

func _on_host_pressed():
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(del_player)
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$MainMenu.hide()

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	player.rpc("setSpawnPos", $SpawnPoint.global_position)
	players[str(id)] = player
	for i in players:
		if players[i]:
			players[i].rpc("requestCharData")

func exit_game(id):
	players.erase(id)
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	print("exot" + str(players.size()))
	get_node(str(id)).queue_free()

@rpc("any_peer", "call_local", "reliable")
func makeFire(dir, pos, n):
	var p = projectile.instantiate()
	$MultiplayerSpawner.add_child(p)
	p.global_position = pos
	p.dir = dir
	p.p = n
	pojectiles.push_front(p)

func _on_item_list_item_clicked(index, at_position, mouse_button_index):
	$CharacterCreation.fileName = $MainMenu/VBoxContainer/ItemList.get_item_text(index) + ".tres"
	$CharacterCreation.loadCharacter()
	$CharacterCreation.visible = true

func _on_button_button_up():
	var fileName = $"MainMenu/VBoxContainer/Character NEW/LineEditCharName".text
	if fileName == "":
		fileName = "NewCharacter"
	
	var newChar = load("user://Characters/Default.tres").duplicate()
	ResourceSaver.save(newChar, "user://Characters/" + fileName + ".tres")
	$MainMenu/VBoxContainer/ItemList.add_item(fileName)
	
func resetAll():
	print("reset all")
	for p in players:
		if players[p]:
			players[p].rpc("reset")
