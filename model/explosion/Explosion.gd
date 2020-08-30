extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal explosion_finished

# Called when the node enters the scene tree for the first time.
func _ready():
	$Shockwave.frame=8

	$Glow.frame=8
	$Glow.modulate = HexoidsColors.lightTextColor.getColor()
	
	$Glow.connect("animation_finished", self, '_on_finished')


func explode(ship):
	visible = true
	ship.add_child(self)
	$Shockwave.modulate = ship.color
	$Shockwave.modulate.a=0.9

	$Shockwave.frame = 0
	$Shockwave.play("explode")
	$Glow.frame = 0
	$Glow.play("explode")
	
func _on_finished():
	emit_signal('explosion_finished', self)
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
