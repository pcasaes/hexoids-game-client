extends CenterContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	_get_line_edit().connect('gui_input', self, '_on_name_set')
	_get_line_edit().grab_focus()
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()

func _on_resize():
	#$OutlineBox.rect_min_size.x = $OutlineBox/VBoxContainer.rect_size.x + 80
	#$OutlineBox.rect_min_size.y = $OutlineBox/VBoxContainer.rect_size.y + 40
	#$OutlineBox/VBoxContainer.rect_position.x = 40
	#$OutlineBox/VBoxContainer.rect_position.y = 20
	pass
	
	
func _on_text_changed(newtext):
	print(newtext)
	
func _on_name_set(ev):
	if ev is InputEventKey and ev.is_pressed() and ev.scancode == KEY_ENTER:
		if _get_line_edit().text.length() >= 3:
			User.username = _get_line_edit().text
			self.visible = false
			Server.start()
			self.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _get_line_edit():
	return $OutlineBox/VBoxContainer/HBoxContainer/LineEdit
