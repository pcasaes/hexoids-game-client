extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_entry(entry):
	var player = store.get(entry.get_playerId().get_guid())
	$Points.text = str(entry.get_score())
	if player != null:
		$Player.text = player.displayName
		_set_color(player.color)
	else:
		$Player.text = HexoidsConfig.world.hud.get_temp_name(entry.get_playerId().get_guid())
		_set_color(HexoidsColors.getDarkTextColor().color)

func _set_color(c):
	$Player.set("custom_colors/font_color", c)
	$Points.set("custom_colors/font_color", c)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
