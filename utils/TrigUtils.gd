extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const FULL_CIRCLE_IN_RADIANS = 2.0 * PI

const HALF_CIRCLE_IN_RADIANS = PI

const QUARTER_CIRCLE_IN_RADIANS = PI / 2.0

const ANTI_QUARTER_CIRCLE_IN_RADIANS = PI / -2.0

const EIGTH_CIRCLE_IN_RADIANS = PI / 4.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func calculateAngleDistance(a, b):
	var abDiff = a - b

	var d = fmod(abs(abDiff), FULL_CIRCLE_IN_RADIANS)
	var r = d
	if d > HALF_CIRCLE_IN_RADIANS:
		r = FULL_CIRCLE_IN_RADIANS - d

	if (abDiff >= 0 && abDiff <= HALF_CIRCLE_IN_RADIANS) || (abDiff <= -HALF_CIRCLE_IN_RADIANS && abDiff >= -FULL_CIRCLE_IN_RADIANS):
		return r
	return -r
