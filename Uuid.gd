# source: https://github.com/binogure-studio/godot-uuid/blob/master/uuid.gd

extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func getRandomInt(max_value):
	randomize()
	return randi() % max_value

func randomBytes(n):
	var r = []
	
	for _index in range(0, n):
		r.append(getRandomInt(256))
		
	return r

func uuidbin():
	var b = randomBytes(16)
	
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	
	return b

func v4():
	var b = uuidbin()
	
	var low = '%02x%02x%02x%02x' % [b[0], b[1], b[2], b[3]]
	var mid = '%02x%02x' % [b[4], b[5]]
	var hi = '%02x%02x' % [b[6], b[7]]
	var clock = '%02x%02x' % [b[8], b[9]]
	var node = '%02x%02x%02x%02x%02x%02x' % [b[10], b[11], b[12], b[13], b[14], b[15]]
	
	return '%s-%s-%s-%s-%s' % [low, mid, hi, clock, node]
