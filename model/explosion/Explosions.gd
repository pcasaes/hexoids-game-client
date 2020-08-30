extends Node2D

export(PackedScene) var explosion_scene

const POOL_SIZE = 16
const POOL_SIZE_MINUS_ONE = 15

const SCREEN_OFFSET = 2000

var playersStore = PlayersStore.store

var pool = []
var next = 0
var using = 0

var cameraStore = CameraStore.store
var viewable_size

# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(POOL_SIZE):
		var s= explosion_scene.instance()
		s.connect('explosion_finished', self, '_explosion_finished')
		pool.push_back(s)
	playersStore.connect('ship_destroyed', self, '_on_ship_destroyed')
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()

func _on_resize():
	viewable_size = (get_viewport_rect().size / 2);
	viewable_size.x = viewable_size.x + SCREEN_OFFSET
	viewable_size.y = viewable_size.y + SCREEN_OFFSET


func _in_viewable_range(ship):
	if cameraStore.camera == null:
		return false
		
	var center = cameraStore.camera.get_camera_screen_center()
	
	var left = center.x - viewable_size.x
	if ship.position.x < left:
		return false
		
	var right = center.x + viewable_size.x
	if ship.position.x > right:
		return false
		
	var top = center.y - viewable_size.y
	if ship.position.y < top:
		return false
		
	var bottom = center.y + viewable_size.y
	if ship.position.y > bottom:
		return false
		
	return true
	
func _on_ship_destroyed(_destroyerId, ship):
	if using < POOL_SIZE and _in_viewable_range(ship):
		var s = pool[next]
		next = (next + 1) & POOL_SIZE_MINUS_ONE
		using = using + 1
		s.explode(ship)

func _explosion_finished(s):
	using = using - 1
	s.get_parent().remove_child(s)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
