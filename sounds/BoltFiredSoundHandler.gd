extends SoundHandler


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('bolt_fired', self, '_on_fired')


func _on_fired(ev, _dto):
	var priority = ev.get_ownerPlayerId().get_guid() == User.getId()	
	play_in_model(priority, ev.get_x(), ev.get_y())




