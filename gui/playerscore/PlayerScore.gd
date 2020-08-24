extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_score_update_command', self, '_on_player_score_updated')
	store.connect('my_player_joined', self, "_on_my_player_joined")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_my_player_joined(player):
	$PlayerScoreEntry.set_player(player)

func _on_player_score_updated(ev, _dto):
	$PlayerScoreEntry.set_entry(ev)
		
