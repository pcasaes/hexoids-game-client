extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var id
var username

# Called when the node enters the scene tree for the first time.
func _ready():
	id = Uuid.v4()
	username = "My Name"


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func getId():
	return id
	
func getUsername():
	return username
	
