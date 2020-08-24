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
	if lastThrustFire > 0.032:
		var te = thrustEffects[nextThrustSprite]
		te.position = pos
		te.frame = 0
		te.play('thrust')
		nextThrustSprite = (nextThrustSprite + 1) & 7
		lastThrustFire = 0		

func set_visible(v):
	for te in thrustEffects:
		te.set_visible(v)	

func set_container(c):
	for te in thrustEffects:
		c.add_child(te)

func _physics_process(delta):
	lastThrustFire = lastThrustFire + delta
