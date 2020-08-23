extends Node2D

const ANIM_THRUST_TIME = 50

# Declare member variables here. Examples:

var create_event
var animThrustEndTime = 0
var current_move_event
var current_move_event_needs_sending = false
var needs_firing = false
var needs_explosion = false
var needs_spawning = false
var color

# Called when the node enters the scene tree for the first time.
func _ready():
	if create_event == null:
		color = HexoidsColors.get(0).getColor()
	else:
		color = 	HexoidsColors.get(create_event.get_ship()).getColor()

	$Ship.modulate = color
	$Ship.play("rest")
	$ShipTint.modulate = color
	$ShipTint.modulate.a = 0.5
	$Wake.set_color(color)
	$Explosion.frame=8
	$Explosion.modulate = color
	$Explosion.modulate.a=0.9
	
func created(ev):
	create_event = ev
	_set_visible(true)
	
func spawned(ev):
	needs_spawning = true
	moved(ev.get_location())	

func moved(ev):
	current_move_event = ev
	current_move_event_needs_sending = true


func moveTo(x, y, angle, thrustAngle, spawned):
	
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

	animThrustEndTime = OS.get_ticks_msec() + ANIM_THRUST_TIME
	
func left(_ev):
	queue_free()	
	$Wake.destroy()
	
func destroyed():
	if $Ship.visible:
		needs_explosion = true

func fired():
	needs_firing = true
	
func _set_visible(v):
	$Ship.set_visible(v)	
	$ShipTint.set_visible(v)	
	$Wake.set_visible(v)	
	
func _physics_process(_delta):
	var spawned = false
	if needs_spawning:
		_set_visible(true)
		needs_spawning = false
		spawned = true
		
	if needs_explosion:
		$Explosion.frame = 0
		$Explosion.play("explode")
		needs_explosion = false
		needs_firing = true
		_set_visible(false)
		$Ship.stop()
	
	if needs_firing:
		$FireEffect.frame = 0
		$FireEffect.play("fire")	
		needs_firing = false	
	
	if $Ship.visible:
		if current_move_event_needs_sending:
			
			var ev = current_move_event
			var thrustAngle;
			if ev.has_method('get_thrustAngle'):
				thrustAngle = ev.get_thrustAngle()
			else:
				thrustAngle = ev.get_angle()
			
			moveTo(
				HexoidsConfig.world.xToView(ev.get_x()),
				HexoidsConfig.world.yToView(ev.get_y()),
				ev.get_angle(),
				thrustAngle,
				spawned
			)
			
			current_move_event_needs_sending = false
			
		var now = OS.get_ticks_msec()
		if animThrustEndTime < now:
			$Ship.play("rest")
		
	


func _on_Main_main_ready(m):
	$Wake.set_container(m)
