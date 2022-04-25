extends Node2D

const HexoidsProto = preload("res://server/HexoidsProto.gd")

const ANIM_THRUST_TIME = 0.05

# Declare member variables here. Examples:

var create_event
var animThrustTime = 0
var color
var id

# Called when the node enters the scene tree for the first time.
func _ready():
	if create_event == null:
		color = HexoidsColors.get(0).getColor()
	else:
		color = HexoidsColors.get(create_event.get_ship()).getColor()

	$Ship.modulate = color
	$Ship.play("rest")
	$ShipTint.modulate = color
	$ShipTint.modulate.a = 0.5
	$Wake.set_color(color)
	
func is_players_ship():
	return User.is_user_from_guid(id)
	
func created(ev):
	create_event = ev
	id = ev.get_playerId().get_guid()
	_set_visible(true)
	
func spawned(ev):
	_set_visible(true)
	moved(ev.get_location(), true)	

func moved(ev, spawned = false, currentView = false):
	var thrustAngle;
	if !currentView:
		thrustAngle = ev.get_thrustAngle()
	else:
		thrustAngle = ev.get_angle()
		
	if !spawned and !currentView and ev.get_reasons().find(HexoidsProto.MoveReason.BLACKHOLE_TELEPORT) > -1:
		modulate.a = 0
		
	
	_moveTo(
		HexoidsConfig.world.xToView(ev.get_x()),
		HexoidsConfig.world.yToView(ev.get_y()),
		ev.get_angle(),
		thrustAngle,
		spawned
	)	


func _moveTo(x, y, angle, thrustAngle, spawned):
	
	rotation = angle
	if spawned:
		position = Vector2(x, y)
		$Wake.move_from(position)
	else:
		$Wake.move_from(position)
		position = Vector2(x, y)
	
	var diff = TrigUtils.calculateAngleDistance(angle, thrustAngle)
	if (abs(diff) <= TrigUtils.EIGTH_CIRCLE_IN_RADIANS):
		$Ship.play("fw-thrust")
	elif (abs(diff - TrigUtils.QUARTER_CIRCLE_IN_RADIANS) <= TrigUtils.EIGTH_CIRCLE_IN_RADIANS):
		$Ship.play("l-thrust")
	elif (abs(diff - PI) <= TrigUtils.EIGTH_CIRCLE_IN_RADIANS):
		$Ship.play("bw-thrust")
	elif (abs(diff + TrigUtils.QUARTER_CIRCLE_IN_RADIANS) <= TrigUtils.EIGTH_CIRCLE_IN_RADIANS):
		$Ship.play("r-thrust")

	animThrustTime = 0
	
func left(_ev):
	queue_free()	
	$Wake.destroy()
	
func destroyed():
	if $Ship.visible:
		_set_visible(false)
		$Ship.stop()
		fired()		

func fired():
	$FireEffect.frame = 0
	$FireEffect.play("fire")	
	
func _set_visible(v):
	$Ship.set_visible(v)	
	$ShipTint.set_visible(v)	
	$Wake.set_visible(v)
	if v:
		modulate.a = 0.0
			
	
func _physics_process(delta):
	if $Ship.visible:
		if modulate.a < 1.0:
			modulate.a = modulate.a + (delta * 3)
		animThrustTime = animThrustTime + delta
		if animThrustTime > ANIM_THRUST_TIME:
			$Ship.play("rest")
		
	


func _on_Main_main_ready(m):
	$Wake.set_container(m)
