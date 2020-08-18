extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store
var lastEvent = null

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('score_board_updated', self, '_on_scoreboard_update')
	
func _physics_process(_delta):
	if lastEvent != null:
		for i in range(lastEvent.get_scores().size()):
			var entry = lastEvent.get_scores()[i]
			var label
			
			if i >= get_child_count():
				label = Label.new()
				add_child(label)
				
			label = get_child(i)
			var player = store.get(entry.get_playerId().get_guid())
			if player != null:
				label.text = player.displayName + ' ' + str(entry.get_score())
				label.set("custom_colors/font_color", player.color)
			else:
				label.text = entry.get_playerId().get_guid().substr(0, HexoidsConfig.world.hud.nameLength) + ' ' + str(entry.get_score())
				label.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)
		lastEvent = null


func _on_scoreboard_update(ev, _dto):
	lastEvent = ev
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

	
