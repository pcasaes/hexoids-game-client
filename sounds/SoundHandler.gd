extends Node2D

class_name SoundHandler

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal play

var sinceLastPlayer = 99999
var type


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func new_player():
	sinceLastPlayer = 0
	return type.instance()	
	
func play_in_model(priority, model_x, model_y):
	if (priority or sinceLastPlayer > 0.1):
		var x = HexoidsConfig.world.xToView(model_x)
		var y = HexoidsConfig.world.yToView(model_y)
		emit_signal('play', self, x, y, priority)
		
func play_in_view(priority, x, y):
	if (priority or sinceLastPlayer > 0.1):
		emit_signal('play', self, x, y, priority)
			


func _physics_process(delta):
	sinceLastPlayer = sinceLastPlayer + delta

