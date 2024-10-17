extends MultiplayerSpawner

@export var PLAYER : PackedScene ## Scene used for auto-spawning the player
var players = {}
@onready var marker_3d: Marker3D = $"../Marker3D"
@onready var players_node = $"../PlayersNode"



func _ready():
	spawn_function = spawnPlayer
	if is_multiplayer_authority():
		spawn(1)
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(removePlayer)
	
	#if is_multiplayer_authority():
		#spawnPlayer(1)
		#multiplayer.peer_connected.connect(spawnPlayer)
		#multiplayer.peer_disconnected.connect(removePlayer)
	
		

func spawnPlayer(data):
	var p = PLAYER.instantiate()
	p.data = data
	p.set_multiplayer_authority(data, true)
	players[data] = p
	Global.players[data] = p
	
	return p

func removePlayer(data):
	players[data].queue_free()
	players.erase(data)
