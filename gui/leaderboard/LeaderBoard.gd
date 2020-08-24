extends VBoxContainer

export (PackedScene) var Entry


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('score_board_updated', self, '_on_scoreboard_update')
	


func _on_scoreboard_update(ev, _dto):
	for i in range(ev.get_scores().size()):
		var entry = ev.get_scores()[i]
		var lbEntry
		
		if i >= get_child_count():
			lbEntry = Entry.instance()
			add_child(lbEntry)
			
		lbEntry = get_child(i)
		lbEntry.set_entry(entry)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

	
