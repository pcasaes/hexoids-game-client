extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	BlackholeStore.connect('blackhole_event', self, '_on_blackhole_event')


func _on_blackhole_event(ev, enabled):
	if !enabled:
		$Label.text = ''
	else:
		var suffix = " collapsed " + str(ev.get_x()) + " x " + str(ev.get_y())
		$Label.text = ev.get_name() + suffix
		$Label.set("custom_colors/font_color", HexoidsColors.getDarkTextColor().color)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
