extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const FireSamplePlayer = preload("res://sounds/FireSamplePlayer.tscn")


const MAX_SAMPLES = 8
const MAX_SAMPLES_MINUS_ONE = 7
const MAX_DISTANCE = 9000

var cameraStore = CameraStore.store
var samples = []
var prioritySamples = []
var next = 0
var nextPriority = 0
var sinceLastPlayer = 99999

# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(MAX_SAMPLES):
		var s = FireSamplePlayer.instance()
		s.max_distance = MAX_DISTANCE
		prioritySamples.push_back(s)
		add_child(s)
		
		s = FireSamplePlayer.instance()
		s.max_distance = MAX_DISTANCE
		s.volume_db = -0.5
		samples.push_back(s)
		add_child(s)
	Server.connect('bolt_fired', self, '_on_fired')


func _on_fired(ev, _dto):
	var priority = ev.get_ownerPlayerId().get_guid() == User.getId()
	
	if cameraStore.camera != null and (priority or sinceLastPlayer > 0.1):
		var center = cameraStore.camera.get_camera_screen_center()
		var x = HexoidsConfig.world.xToView(ev.get_x())
		var y = HexoidsConfig.world.yToView(ev.get_y())
		if priority:
			var s = prioritySamples[nextPriority]
			if !s.playing:
				_play(s, x, y, 0)
				nextPriority = (nextPriority+1) & MAX_SAMPLES_MINUS_ONE
		elif !samples[next].playing:
			var disX = pow(x - center.x, 2.0)
			var disY = pow(y - center.y, 2.0)
			var dist = sqrt(disY + disX)
			if dist < MAX_DISTANCE:
				var s = samples[next]
				_play(s, x, y, dist)
				next = (next+1) & MAX_SAMPLES_MINUS_ONE
	
func _play(s, x, y, d):
	s.position.x = x
	s.position.y = y
	if d < 2000:
		s.set_bus("Master")
	elif d < 4000:
		s.set_bus("MID")
	else:
		s.set_bus("BACK")
	s.play(0)
	sinceLastPlayer = 0
	
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	sinceLastPlayer = sinceLastPlayer + delta


