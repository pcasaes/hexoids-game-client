extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const MAX_DISTANCE = 9000

const MAX_DISTANCE_SQUARED = pow(MAX_DISTANCE, 2)

const MASTER_MAX_DISTANCE_SQUARED = pow(1000, 2)

const MID_MAX_DISTANCE_SQUARED = pow(2000, 2)

var cameraStore = CameraStore.store

var enabled = true setget set_enabled,get_enabled

# Called when the node enters the scene tree for the first time.
func _ready():
	for c in get_children():
		c.connect('play', self, '_play')

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_enabled(v):
	if v != enabled:
		enabled = v
		for c in get_children():
			c.enabled = v

func get_enabled():
	return enabled

func _play(s, x, y, priority):
	var distSquared
	
	if priority:
		distSquared = 0
	elif is_instance_valid(cameraStore.camera):
		var center = cameraStore.camera.get_camera_screen_center()
		var disX = pow(x - center.x, 2)
		var disY = pow(y - center.y, 2)
		distSquared = disY + disX
	else:
		distSquared = MAX_DISTANCE_SQUARED

	
	if distSquared < MAX_DISTANCE_SQUARED:
		s.max_distance = MAX_DISTANCE
		if priority:
			s.attenuation = 1
			s.volume_db = 0
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
			
		s.play(0)


func _input(event):
	if event.is_action_pressed("ui_toggle_mute"):
		set_enabled(not enabled)
