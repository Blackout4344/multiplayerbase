extends Node


func _ready():
	OS.set_environment("SteamAppID", "1923730")
	OS.set_environment("SteamGameID", "1923730")
	print(Steam.steamInitEx())
	print(Steam.getPersonaName())

	print("plum throw????")
	

func _process(_delta):
	Steam.run_callbacks()
