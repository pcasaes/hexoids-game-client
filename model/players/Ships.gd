extends Node2D


# Declare member variables here. Examples:

var store = PlayersStore.store
var main
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	store.connect('player_created', self, '_player_created')


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _player_created(ship, child, _isUser):
	add_child(child)
	ship._on_Main_main_ready(main)	


func _on_Main_main_ready(m):
	main = m
	for s in store.all():
		s._on_Main_main_ready(m)
