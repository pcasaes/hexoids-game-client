extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$VBoxContainer/HBoxContainer/LineEdit.connect('gui_input', self, '_on_name_set')
	$VBoxContainer/HBoxContainer/LineEdit.grab_focus()

func _on_text_changed(newtext):
	print(newtext)
	
func _on_name_set(ev):
	if ev is InputEventKey and ev.is_pressed() and ev.scancode == KEY_ENTER:
		if $VBoxContainer/HBoxContainer/LineEdit.text.length() >= 3:
			User.username = $VBoxContainer/HBoxContainer/LineEdit.text
			self.visible = false
			Server.start()
			self.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
