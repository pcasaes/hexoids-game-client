extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const LOG_SIZE = 4

export (PackedScene) var PlayerDestroyedAction

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_destroyed', self, '_on_player_destroyed')


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_player_destroyed(ev, _dto):
	if get_child_count() < LOG_SIZE:
		var label = PlayerDestroyedAction.instance()
		label.loadEvent(ev)
		add_child(label)
	else:
		var label = get_child(0)
		remove_child(label)
		label.loadEvent(ev)
		add_child(label)		
		
	

