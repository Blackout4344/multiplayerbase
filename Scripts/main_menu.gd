extends Control

var lobby_id = 0
#var peer = SteamMultiplayerPeer.new()
@onready var ms = $MultiplayerSpawner
@onready var lobbies_parent = $LobbyContainer/Lobbies
@onready var no_lobbies = $LobbyContainer/NoLobbies
@onready var ui = $UI
@onready var lobby_container: ScrollContainer = $LobbyContainer
@onready var refresh_button: Button = $RefreshButton
@onready var back_button: Button = $BackButton


func _ready():
	ms.spawn_function = spawn_level
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_LobbyJoined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.network_messages_session_failed.connect(_network_messages_session_failed)
	open_lobby_list()


func spawn_level(data):
	var a = (load(data) as PackedScene).instantiate()
	return a

func _on_host_button_pressed() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 8)
	
	await get_tree().create_timer(1).timeout
	
	var peer : SteamMultiplayerPeer = SteamMultiplayerPeer.new()
	var err = peer.create_host(0)
	if err:
		print("ERROR OCCURED WHEN CREATING LOBBY: ", err)
		
	#peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
	multiplayer.multiplayer_peer = peer
	ms.spawn("res://Scenes/Main.tscn")
	hide()


func _on_join_button_pressed() -> void:
	ui.visible = false
	lobby_container.visible = true
	refresh_button.visible = true
	back_button.visible = true

func join_lobby(id):
	Steam.joinLobby(id)
	await get_tree().create_timer(1).timeout
	var peer : SteamMultiplayerPeer = SteamMultiplayerPeer.new()
	var err = peer.create_client(Steam.getLobbyOwner(id), 0)
	
	if err:
		print(err)
	
#	peer.connect_lobby(id)
	multiplayer.multiplayer_peer = peer
	lobby_id = id
	hide()

func _on_LobbyJoined(lobbyId, permissions, locked, response):
	if (response == Steam.RESULT_OK):
		print("STEAM: Lobby Joined!")
	else:
		print("STEAM: Failed to join Lobby! Reason: ", response)


func _on_lobby_created(connect_, id):
	if connect_:
		lobby_id = id
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName() + "'s Lobby"))
		Steam.setLobbyJoinable(lobby_id, true)

func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()


func _on_lobby_match_list(lobbies):
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var mem_count = Steam.getNumLobbyMembers(lobby)
		
		var btn = Button.new()
		btn.set_text(str(lobby_name, " || Joined: ", mem_count, " Players"))
		btn.set_size(Vector2(100, 5))
		btn.focus_mode = Control.FOCUS_NONE
		btn.connect("pressed", Callable(self, "join_lobby").bind(lobby))
		lobbies_parent.add_child(btn)
	if lobbies_parent.get_child_count() == 0:
		no_lobbies.show()
	else:
		no_lobbies.hide()

@rpc("any_peer", "call_local")
func delete_player(id = 0):
	if id == 0:
		id = multiplayer.multiplayer_peer.get_unique_id()
	
	
	Steam.leaveLobby(lobby_id)
	
	Global.players[id].queue_free()
	Global.players.erase(id)
	
	if id == 1:
		print("Host left, kicking all players")
		delete_player.rpc()
	
	multiplayer.multiplayer_peer.close()
	

func _on_refresh_button_pressed() -> void:
	if lobbies_parent.get_child_count() > 0:
		for n in lobbies_parent.get_children():
			n.queue_free()
	open_lobby_list()

func _network_messages_session_failed(_reason : int, _remote_steam_id : int, _connection_status : int, _debug_state : String) -> void:
	print("Network message session failed\nReason: ", _reason, "\nRemote Steam ID: ", _remote_steam_id, "\nConnection Status: ", _connection_status, "\nDebug State: ", _debug_state)
	
	if _connection_status == Steam.CONNECTION_STATE_PROBLEM_DETECTED_LOCALLY:
		rpc(delete_player())

func _on_back_button_pressed() -> void:
	ui.visible = true
	lobby_container.visible = false
	refresh_button.visible = false
	back_button.visible = false
