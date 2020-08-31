extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const LEFT_SUFFIX = '_L'
const RIGHT_SUFFIX = '_R'
const MUTE_DB = -112

export(Resource) var stream setget set_stream,get_stream

signal finished
signal started

var max_distance setget set_max_distance,get_max_distance
var viewable_size
var viewable_size_squared

var _max_distance_squared

var cameraStore = CameraStore.store

var volume_db = 0

var attenuation = 1

var _left_player
var _right_player

# Called when the node enters the scene tree for the first time.
func _ready():
	_left_player = $Left
	_right_player = $Right
	$Left.connect('finished', self, '_on_finished')
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()

func _on_resize():
	viewable_size = (get_viewport_rect().size / 2);
	viewable_size_squared = Vector2(pow(viewable_size.x, 2), pow(viewable_size.y, 2))
	
func set_stream(s):
	stream = s
	$Left.stream = s
	$Right.stream = s
	
func get_stream():
	return stream


func set_max_distance(m):
	if max_distance != m:
		max_distance = m
		_max_distance_squared = pow(m, 2)
	
func get_max_distance():
	return max_distance	

func set_bus(b):
	$Left.set_bus(b + LEFT_SUFFIX)
	$Right.set_bus(b + RIGHT_SUFFIX)
	
func play(_p):
	if cameraStore.camera != null:
		_pan()
		_dist()
		_apply_db()
		$Left.play(_p)
		$Right.play(_p)
		emit_signal('started')

func _dist():
	var center = cameraStore.camera.get_camera_screen_center()
	var disX = pow(position.x - center.x, 2)
	var disY = pow(position.y - center.y, 2)
	var distSquared = (disY + disX)
	
	if distSquared < _max_distance_squared:
		if distSquared > 0:
			var v = (distSquared - _max_distance_squared) / _max_distance_squared
			if attenuation != 1:
				v = pow(v, attenuation)
			var db = MathUtils.rms_to_db(v)			
			$Left.volume_db = $Left.volume_db + db
			$Right.volume_db = $Right.volume_db + db
	else:
		$Left.volume_db = MUTE_DB
		$Right.volume_db = MUTE_DB
	
	
func _apply_db():
	$Left.volume_db = $Left.volume_db + volume_db
	$Right.volume_db = $Right.volume_db + volume_db
		

	
func _pan():
	var center = cameraStore.camera.get_camera_screen_center()

	if (position.x < center.x - viewable_size.x):
		$Left.volume_db = 0
		$Right.volume_db = MUTE_DB
	elif (position.x > center.x + viewable_size.x):
		$Left.volume_db = MUTE_DB
		$Right.volume_db = 0
	elif (position.x < center.x):
		var v = 1 - (center.x - position.x) / viewable_size.x
		var db = MathUtils.rms_to_db(v)
		$Left.volume_db = 0
		$Right.volume_db = db
	elif (position.x > center.x):
		var v = 1 - (position.x - center.x) / viewable_size.x
		var db = MathUtils.rms_to_db(v)
		$Left.volume_db = db
		$Right.volume_db = 0
	else:
		$Left.volume_db = 0
		$Right.volume_db = 0

func _on_finished():
	emit_signal('finished')
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
