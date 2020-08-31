extends Node2D

class_name SoundHandler

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const MAX_POOL_SIZE = 4
const MAX_POOL_SIZE_MINUS_ONE = MAX_POOL_SIZE - 1

export(PackedScene) var type

signal play

var sinceLastPlayer = 99999

var priorityPool = []
var regularPool = []

var regularNext = 0
var priorityNext = 0

var regularPlaying = 0
var priorityPlaying = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in range(MAX_POOL_SIZE):
		var p

		p = type.instance()
		p.get_player().connect('finished', self, '_on_finished_priority')
		p.get_player().connect('started', self, '_on_started_priority')
		priorityPool.push_back(p)
		add_child(p)

		p = type.instance()
		p.get_player().connect('finished', self, '_on_finished_regular')
		p.get_player().connect('started', self, '_on_started_regular')
		regularPool.push_back(p)
		add_child(p)

func play_in_model(priority, model_x, model_y):
	if (priority or sinceLastPlayer > 0.1):
		var x = HexoidsConfig.world.xToView(model_x)
		var y = HexoidsConfig.world.yToView(model_y)
		_play(x, y, priority)
		
func play_in_view(priority, x, y):
	if (priority or sinceLastPlayer > 0.1):
		_play(x, y, priority)
			
func _play(x, y, priority):
	if priority:
		if priorityPlaying < MAX_POOL_SIZE:
			var p = priorityPool[priorityNext]
			emit_signal('play', p.get_player(), x, y, priority)
	else:
		if regularPlaying < MAX_POOL_SIZE:
			var p = regularPool[regularNext]
			emit_signal('play', p.get_player(), x, y, priority)

func _physics_process(delta):
	sinceLastPlayer = sinceLastPlayer + delta

func _on_finished_priority():
	priorityPlaying = priorityPlaying - 1

func _on_finished_regular():
	regularPlaying = regularPlaying - 1
	
func _on_started_regular():
	sinceLastPlayer = 0
	regularNext = (regularNext + 1) & MAX_POOL_SIZE_MINUS_ONE
	regularPlaying = regularPlaying + 1
		
func _on_started_priority():
	sinceLastPlayer = 0
	priorityNext = (priorityNext + 1) & MAX_POOL_SIZE_MINUS_ONE
	priorityPlaying = priorityPlaying + 1
		


