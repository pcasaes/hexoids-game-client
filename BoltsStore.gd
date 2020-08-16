extends Node

var store = BoltsStore.new() setget ,get_store


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


class BoltsStore:
	var bolts = {}
	
	func set(guid, p):
		bolts[guid] = p
		
	func remove(guid):
		bolts.erase(guid)
		
	func get(uuid):
		return bolts.get(uuid)
		
	func all():
		return bolts.values()
