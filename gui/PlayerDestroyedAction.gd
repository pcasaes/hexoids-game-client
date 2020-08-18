extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var store = GUIStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	$Time.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)
	$Action.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)


func setPlayer(guid, label):
	var p = store.get(guid)
	if p != null:
		label.text = p.displayName
		label.set("custom_colors/font_color", p.color)
	else:
		label.text = guid.substr(0, HexoidsConfig.world.hud.nameLength)
		label.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)

func getTimePart(p):
	var h = p
	if (h.length() == 1):
		h = '0' + h
	return h

func loadEvent(ev):
	setPlayer(ev.get_destroyedByPlayerId().get_guid(), $Destroyer)
	setPlayer(ev.get_playerId().get_guid(), $Destroyee)
	var dt = OS.get_datetime_from_unix_time(ev.get_destroyedTimestamp() / 1000)
	
	$Time.text = getTimePart(str(dt.hour)) + getTimePart(str(dt.minute)) + getTimePart(str(dt.second))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
