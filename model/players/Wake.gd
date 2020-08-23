extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (int) var size = 8
export (PackedScene) var ThrustEffect


var thrustEffects = []
var nextThrustSprite = 0
var lastThrustFire = 0

var color setget set_color

# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(size):
		var te = ThrustEffect.instance()
		thrustEffects.push_back(te)

func destroy():
	for te in thrustEffects:
		te.queue_free()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_color(c):
	color = Color(c.r, c.g, c.b, 0.7);
	for te in thrustEffects:
		te.modulate = color
		
func move_from(pos):
	var now = OS.get_ticks_msec()
	if now - lastThrustFire > 32:
		#var diffPosition = position - nextPosition		
		var te = thrustEffects[nextThrustSprite]
		#te.position = diffPosition
		te.position = pos
		te.frame = 0
		te.play('thrust')
		nextThrustSprite = (nextThrustSprite + 1) & 7
		lastThrustFire = now		

func set_container(c):
	for te in thrustEffects:
		c.add_child(te)
