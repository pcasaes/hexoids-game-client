extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var boltId

var fired_event
var endTime
var velX
var velY
var speed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _physics_process(_delta):
	if visible:
		var now = HClock.clock.gameTime()
		if endTime < now:
			visible = false
		else:
			var velocityDelta = speed * (now - fired_event.get_startTimestamp())
			var newX = fired_event.get_x() + velocityDelta * velX
			var newY = fired_event.get_y() + velocityDelta * velY
			moveTo(HexoidsConfig.world.xToView(newX), HexoidsConfig.world.yToView(newY))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func fired(ev):
	fired_event = ev
	velX = cos(ev.get_angle())
	velY = sin(ev.get_angle())
	endTime = ev.get_startTimestamp() * ev.get_ttl()
	speed = fired_event.get_speed() / 1000.0
	var ship = PlayersStore.store.get(ev.get_ownerPlayerId().get_guid())
	if ship != null:
		$AnimatedSprite.modulate = ship.color
		$Wake.modulate = ship.color
		$Wake.modulate.a = 0.7
		ship.fired()

	
func moveTo(x, y):	
	position = Vector2(x, y)
