extends Node2D


# Declare member variables here. Examples:

var store = BoltsStore.store


# Called when the node enters the scene tree for the first time.
func _ready():
	store.connect('bolt_created', self, '_on_bolt_created')
	store.connect('bolt_destroyed', self, '_on_bolt_destroyed')


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_bolt_created(bolt):
	add_child(bolt)
	
	
func _on_bolt_destroyed(bolt):
	remove_child(bolt)	
