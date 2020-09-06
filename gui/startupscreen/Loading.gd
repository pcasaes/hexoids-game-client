extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var _fade_out = false
var _fade_out_spacing_time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

		
func fade_out():
	_fade_out = true

func _physics_process(delta):
	$CenterContainer/Animation/Animation.rotate(delta)

	if _fade_out:		
		$CenterContainer/Animation.rect_min_size.y = $CenterContainer/Animation.rect_min_size.y + 2
		_fade_out_spacing_time = _fade_out_spacing_time + delta
		if _fade_out_spacing_time > 0.06:
			var font = $Title.get("custom_fonts/font")
			font.extra_spacing_char = font.extra_spacing_char + 1
			_fade_out_spacing_time = 0
