extends Node

var store = PlayersStore.new() setget ,get_store


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_store():
	return store
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


class PlayersStore:
	var players = {}
	
	func set(guid, p):
		players[guid] = p
		
	func remove(guid):
		players.erase(guid)
		
	func get(uuid):
		return players.get(uuid)
		
	func all():
		return players.values()
		
	func clear():
		players.clear()
