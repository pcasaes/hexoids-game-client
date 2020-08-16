extends Node

var clock = HClock.new() setget ,get_clock

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_clock():
	return clock
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

class HClock:
	var offset
	
	func clientTime():
		return OS.get_system_time_msecs();
		
	func gameTime():
		#FIXME should return game time
		return OS.get_system_time_msecs() + offset;
		
	func onClockSync(requestTime, s):
		offset = s.get_time() - (requestTime + (clientTime() - requestTime) / 2);
		print('Clock: client to server offset = ', offset)
	  
