extends Node2D

const HexoidsProto = preload("res://server/HexoidsProto.gd")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var cameraStore = CameraStore.store

var captured = false

var forwardDir = 0
var lockAngle = false
var lockPosition = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var camera = $Camera2D
	cameraStore.camera = $Camera2D
	
	camera.limit_bottom = HexoidsConfig.world.maximum.y
	camera.limit_right = HexoidsConfig.world.maximum.x
	
	remove_child($Camera2D)
	$Ship.add_child(camera)
	
	var request = HexoidsProto.RequestCommand.new()
	request.new_spawn()
	Server.sendMessage(request)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	cameraStore.camera = $Camera2D


func _input(event):
	if event.is_action_pressed("click"):
		captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		captured = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event.is_action_pressed("ui_dir_fwrd"):
		forwardDir = 0
	elif event.is_action_pressed("ui_dir_right"):
		forwardDir = TrigUtils.QUARTER_CIRCLE_IN_RADIANS
	elif event.is_action_pressed("ui_dir_back"):
		forwardDir = TrigUtils.HALF_CIRCLE_IN_RADIANS
	elif event.is_action_pressed("ui_dir_left"):
		forwardDir = TrigUtils.ANTI_QUARTER_CIRCLE_IN_RADIANS
	elif event.is_action_pressed("ui_lock_angle"):
		lockAngle = true
	elif event.is_action_released("ui_lock_angle"):
		lockAngle = false
	elif event.is_action_pressed("ui_lock_position"):
		lockPosition = true
	elif event.is_action_released("ui_lock_position"):
		lockPosition = false
	elif event.is_action_pressed("ui_fire"):
		var request = HexoidsProto.RequestCommand.new()
		var _fire = request.new_fire()
		Server.sendMessage(request)
	elif captured and event is InputEventMouseMotion:
		var request = HexoidsProto.RequestCommand.new()
		var move = request.new_move()		
		if !lockPosition or lockAngle == lockPosition:
			move.set_moveX(HexoidsConfig.world.xToModel(event.relative.x))
			move.set_moveY(HexoidsConfig.world.yToModel(event.relative.y))
		if !lockAngle or lockAngle == lockPosition:
			move.new_angle().set_value(atan2(event.relative.y, event.relative.x)+forwardDir)
		
		Server.sendMessage(request)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func ship():
	return $Ship
	
