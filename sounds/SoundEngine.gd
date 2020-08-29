extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const MAX_DISTANCE = 9000

const MAX_DISTANCE_SQUARED = pow(MAX_DISTANCE, 2.0)

const MASTER_MAX_DISTANCE_SQUARED = pow(1000, 2.0)

const MID_MAX_DISTANCE_SQUARED = pow(2000, 2.0)

var cameraStore = CameraStore.store


# Called when the node enters the scene tree for the first time.
func _ready():
	for c in get_children():
		c.connect('play', self, '_play')

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _play(handler, x, y, priority):
	var distSquared
	
	if priority:
		distSquared = 0
	elif cameraStore.camera != null:
		var center = cameraStore.camera.get_camera_screen_center()
		var disX = pow(x - center.x, 2.0)
		var disY = pow(y - center.y, 2.0)
		distSquared = disY + disX
	else:
		distSquared = MAX_DISTANCE_SQUARED

	
	if distSquared < MAX_DISTANCE_SQUARED:
		var s = handler.new_player()
		s.max_distance = MAX_DISTANCE
		if priority:
			s.attenuation = 1
		else:
			s.attenuation = 8
			s.volume_db = -0.5
			
	
		s.position.x = x
		s.position.y = y
		if distSquared < MASTER_MAX_DISTANCE_SQUARED:
			s.set_bus("Master")
		elif distSquared < MID_MAX_DISTANCE_SQUARED:
			s.set_bus("MID")
		else:
			s.set_bus("BACK")
			
		s.connect('finished', s, 'queue_free')			
		add_child(s)
