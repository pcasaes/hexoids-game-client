extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

class SymVer:
	
	var major
	
	var minor
	
	var patch
	
	func _init(string_value):
		var sp = string_value.rsplit('.')
		major = sp[0]
		minor = sp[1]
		patch = sp[2]
		
	func equalTo(other):
		return major == other.major and minor == other.minor and patch == other.patch
		
	func greaterThan(other):
		if major < other.major:
			return false
		elif major > other.major:
			return true
			
		if minor < other.minor:
			return false
		elif minor > other.minor:
			return true
		
		if patch < other.patch:
			return false
		elif patch > other.patch:
			return true
		
		return false
		
	func greaterThanOrEqualTo(other):
		return equalTo(other) or greaterThan(other)
		
	func lessThan(other):
		return not greaterThanOrEqualTo(other)
		
	func lessThanOrEqualTo(other):
		return not greaterThan(other)
		
