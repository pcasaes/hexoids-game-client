extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var PlayerDestroyedAction

var store = GUIStore.store
var logSize = 4
var logSizeMinusOne = logSize - 1
var actions = []
var action_start_index = 0
var action_length = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(logSize):
		actions.push_back(null)
	Server.connect('player_destroyed', self, '_on_player_destroyed')


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(_delta):
	for i in range(action_length):
		var ev = actions[(action_start_index + i)&logSizeMinusOne]
		if get_child_count() < logSize:
			var label = PlayerDestroyedAction.instance()
			label.loadEvent(ev)
			add_child(label)
		else:
			var label = get_child(0)
			remove_child(label)
			label.loadEvent(ev)
			add_child(label)
			
	action_start_index = 0
	action_length = 0

func _on_player_destroyed(ev, _dto):
	if action_length < logSize:
		actions[(action_start_index + action_length)&logSizeMinusOne] = ev
		action_length = action_length + 1
	else:
		action_start_index = (action_start_index+1)&logSizeMinusOne
		actions[(action_start_index + action_length)&logSizeMinusOne] = ev
		
		
	

