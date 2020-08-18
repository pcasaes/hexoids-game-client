extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store
var lastEvent = null

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('player_score_update_command', self, '_on_player_score_updated')

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(_delta):
	if lastEvent != null:
		var playerId = store.getMyPlayerId()
		var p = store.get(playerId)
		if p != null:
			$Label.text = p.displayName + ' ' + str(lastEvent.get_score())
			$Label.set("custom_colors/font_color", p.color)
		else:		
			$Label.text =playerId.substr(0, HexoidsConfig.world.hud.nameLength) + ' ' + str(lastEvent.get_score())
			$Label.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)
		lastEvent = null

func _on_player_score_updated(ev, _dto):
	lastEvent = ev
		
