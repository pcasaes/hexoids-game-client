extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var boltId

var endTime
var velX
var velY
var speed

var calculateFromTimestamp
var calculateFromX
var calculateFromY

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _physics_process(_delta):
	if visible:
		var now = HClock.clock.gameTime()
		if endTime < now:
			visible = false
		else:
			var velocityDelta = speed * (now - calculateFromTimestamp)
			var newX = calculateFromX + velocityDelta * velX
			var newY = calculateFromY + velocityDelta * velY
			moveTo(HexoidsConfig.world.xToView(newX), HexoidsConfig.world.yToView(newY))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	
func diverted(ev):
	calculateFromTimestamp = ev.get_divertTimestamp()
	calculateFromX = ev.get_x()
	calculateFromY = ev.get_y()
	velX = cos(ev.get_angle())
	velY = sin(ev.get_angle())
	speed = ev.get_speed() / 1000.0
	

func fired(ev):
	calculateFromTimestamp = ev.get_startTimestamp();
	calculateFromX = ev.get_x()
	calculateFromY = ev.get_y()
	velX = cos(ev.get_angle())
	velY = sin(ev.get_angle())
	endTime = calculateFromTimestamp + ev.get_ttl()
	speed = ev.get_speed() / 1000.0
	var ship = PlayersStore.store.get(ev.get_ownerPlayerId().get_guid())
	if ship != null:
		$AnimatedSprite.modulate = ship.color
		$Wake.modulate = ship.color
		$Wake.modulate.a = 0.9
		ship.fired()

	
func moveTo(x, y):	
	position = Vector2(x, y)
