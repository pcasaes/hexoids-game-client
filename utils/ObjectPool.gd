extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var factory = PoolFactory.new() setget ,get_factory

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_factory():
	return factory
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

class PoolFactory:
	func newPool(size, scene):
		return Pool.new(size, scene)

class Pool:
	var _list
	var _size
	var _size_minus_one
	var _returnIndex
	var _borrowIndex
	var _scene
	var _available
	
	func _init(size, scene):
		_scene = scene
		_size = size
		_size_minus_one = size -1
		_available = size
		_returnIndex = 0
		_borrowIndex = 0

		_list = [];
		for _i in range(_size):
			_list.push_back(scene.instance())
			
		
	func borrowObject():
		if _available > 0:
			_available = _available - 1
			var o = _list[_borrowIndex]
			_borrowIndex = (_borrowIndex + 1) & _size_minus_one
			return o
		else:
			return _scene.instance()	
			
	func returnObject(o):
		if _available < _size:
			_available = _available + 1
			_list[_returnIndex] = o
			_returnIndex = (_returnIndex + 1) & _size_minus_one
		else:
			o.queue_free()
	
