extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const LOG_10 = log(10)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func log10(v):
	return log(v) / LOG_10
	
func rms_to_db(v):
	if v == 0:
		return 0
	return 0 - 10 * MathUtils.log10(1.0/ pow(v,2))		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
