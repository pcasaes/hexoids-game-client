extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const Barrier = preload("res://model/barriers/Barrier.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('current_view_command', self, '_on_current_view_command')

func _on_current_view_command(cmd, _dto):
	for b in cmd.get_barriers():
		var barrier = Barrier.instance()
		barrier.position.x = HexoidsConfig.world.xToView(b.get_x())
		barrier.position.y = HexoidsConfig.world.yToView(b.get_y())
		barrier.rotation = b.get_angle()
		add_child(barrier)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
