extends Node

var world = HexoidsWorld.new() setget ,get_world

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_world():
	return world

class HexoidsWorld:
	
	var renderOffset = 128 setget ,get_renderOffset
	var minimum = Vector2(0, 0) setget ,get_minimum
	var maximum = Vector2(10000, 10000) setget ,get_maximum
	var hud = HudConfig.new() setget ,get_hud

	func get_renderOffset():
		return renderOffset
		
	func get_minimum():
		return minimum
		
	func get_maximum():
		return maximum
		
	func xToView(x):
		return x * maximum.x
		
	func yToView(y):
		return y * maximum.y
		
	func xToModel(x):
		return x / float(maximum.x)
		
	func yToModel(y):
		return y / float(maximum.y)
		
	func get_hud():
		return hud
		
class HudConfig:
	var nameLength = 8 setget ,get_nameLength
	
	func get_nameLength():
		return nameLength	
