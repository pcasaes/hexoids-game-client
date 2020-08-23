extends Node2D


signal main_ready
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal('main_ready', self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
