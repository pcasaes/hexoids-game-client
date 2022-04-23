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

var requestWithAngle
var requestWithoutAngle

var min_inertial_dampen_factor = 0.000001

var is_min_inertial_dampen_factor = false

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

	requestWithAngle = HexoidsProto.RequestCommand.new()
	requestWithAngle.new_move().new_angle()

	requestWithoutAngle = HexoidsProto.RequestCommand.new()
	requestWithoutAngle.new_move()


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
	elif event.is_action_released("ui_min_inertial_dampen_factor_1"):
		min_inertial_dampen_factor = 0.5
		if is_min_inertial_dampen_factor:
			_set_inertial_dampen(min_inertial_dampen_factor)
	elif event.is_action_released("ui_min_inertial_dampen_factor_2"):
		min_inertial_dampen_factor = 0.1
		if is_min_inertial_dampen_factor:
			_set_inertial_dampen(min_inertial_dampen_factor)
	elif event.is_action_released("ui_min_inertial_dampen_factor_3"):
		min_inertial_dampen_factor = 0.01
		if is_min_inertial_dampen_factor:
			_set_inertial_dampen(min_inertial_dampen_factor)
	elif event.is_action_released("ui_min_inertial_dampen_factor_4"):
		min_inertial_dampen_factor = 0.001
		if is_min_inertial_dampen_factor:
			_set_inertial_dampen(min_inertial_dampen_factor)
	elif event.is_action_released("ui_min_inertial_dampen_factor_5"):
		min_inertial_dampen_factor = 0.00005
		if is_min_inertial_dampen_factor:
			_set_inertial_dampen(min_inertial_dampen_factor)
	elif event.is_action_released("ui_min_inertial_dampen_factor_6"):
		min_inertial_dampen_factor = 0.000001
		if is_min_inertial_dampen_factor:
			_set_inertial_dampen(min_inertial_dampen_factor)
	elif event.is_action_released("ui_max_inertial_dampen_factor"):
		is_min_inertial_dampen_factor = false
		_set_inertial_dampen(1)
	elif event.is_action_released("ui_min_inertial_dampen_factor"):
		is_min_inertial_dampen_factor = true;
		_set_inertial_dampen(min_inertial_dampen_factor)
	elif event.is_action_pressed("ui_fire"):
		var request = HexoidsProto.RequestCommand.new()
		var _fire = request.new_fire()
		Server.sendMessage(request)
	elif captured and event is InputEventMouseMotion:
		var request
		var withAngle = !lockAngle
		var withPosition = !lockPosition
		
		if withAngle or withPosition:
			if withAngle:
				request = requestWithAngle
			else:
				request = requestWithoutAngle
			
			var move = request.get_move()		
			if withPosition:
				move.set_moveX(HexoidsConfig.world.xToModel(event.relative.x))
				move.set_moveY(HexoidsConfig.world.yToModel(event.relative.y))
			else:
				move.set_moveX(0)
				move.set_moveY(0)
			
			if withAngle:
				var angle = move.get_angle();
				angle.set_value(atan2(event.relative.y, event.relative.x)+forwardDir)
			
			Server.sendMessage(request)


func _set_inertial_dampen(factor):
	var request = HexoidsProto.RequestCommand.new()
	var _inertialDampenFactor = request.new_setFixedIntertialDampenFactor()
	_inertialDampenFactor.set_factor(factor)
	Server.sendMessage(request)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func ship():
	return $Ship
	
