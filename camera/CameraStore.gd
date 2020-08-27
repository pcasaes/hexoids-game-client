extends Node

var store = CameraStore.new() setget ,get_store


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func get_store():
	return store

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

class CameraStore:
	
	var camera
