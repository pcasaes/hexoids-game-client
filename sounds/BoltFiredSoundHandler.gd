extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const FireSamplePlayer = preload("res://sounds/FireSamplePlayer.tscn")


const MAX_SAMPLES = 4
const MAX_SAMPLES_MINUS_ONE = 3
const MAX_DISTANCE = 2000

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
		prioritySamples.push_back(s)
		add_child(s)
		
		s = FireSamplePlayer.instance()
		samples.push_back(s)
		add_child(s)
	Server.connect('bolt_fired', self, '_on_fired')


func _on_fired(ev, dto):
	var priority = ev.get_ownerPlayerId().get_guid() == User.getId()
	
	if cameraStore.camera != null and (priority or sinceLastPlayer > 0.1):
		var center = cameraStore.camera.get_camera_screen_center()
		var x = HexoidsConfig.world.xToView(ev.get_x())
		var y = HexoidsConfig.world.yToView(ev.get_y())
		if priority:
			var s = prioritySamples[nextPriority]
			if !s.playing:
				_play(s, x, y)
				nextPriority = (nextPriority+1) & MAX_SAMPLES_MINUS_ONE
		elif abs(x - center.x) < MAX_DISTANCE and abs(y - center.y) < MAX_DISTANCE:
			var s = samples[next]
			if !s.playing:
				_play(s, x, y)
				next = (next+1) & MAX_SAMPLES_MINUS_ONE
	
func _play(s, x, y):
	s.position.x = x
	s.position.y = y
	s.play(0)
	sinceLastPlayer = 0
	
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	sinceLastPlayer = sinceLastPlayer + delta


