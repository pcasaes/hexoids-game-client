extends Node

class HexoidsColor:
	var color
	var lighterColor
	
	func _init(rgb):
		color = Color(rgb)
		lighterColor = color.lightened(0.1)
		
	func transformByDegrees(degrees):
		if (degrees < 0):
			degrees = 360 + degrees
	
		if (degrees > 360):
			degrees = degrees % 360
		
		var h = ((int(color.h * 360) + degrees) % 360) / 360.0
	
		return HexoidsColor.new(Color.from_hsv(h, color.s, color.v).to_html())
		
	func getColor():
		return color

var pallete = []
var _size = 0
var primaryColor
var darkTextColor
var lightTextColor

func create(_primaryColor, hues, offset):
	_size = hues * 2
	primaryColor = _primaryColor
	var deg = 360 / hues
	var c = HexoidsColor.new(primaryColor)
	pallete.push_back(c)
	pallete.push_back(c.transformByDegrees(offset))
	for i in range(0, _size, 2):
		c = pallete[i].transformByDegrees(deg)
		pallete.push_back(c)
		pallete.push_back(c.transformByDegrees(offset))
		
	
	darkTextColor = HexoidsColor.new("#126575")
	lightTextColor = HexoidsColor.new("#26dafd")


func size():
	return _size

func get(i):
	return pallete[i % size()]
	
func getDarkTextColor():
	return darkTextColor



func _init():
	create('#26dafd', 6, 20)
	
