extends SoundHandler


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const fire_res = preload("res://sounds/samples/fire_res.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	type = fire_res
	Server.connect('bolt_fired', self, '_on_fired')


func _on_fired(ev, _dto):
	var priority = ev.get_ownerPlayerId().get_guid() == User.getId()	
	play_in_model(priority, ev.get_x(), ev.get_y())




