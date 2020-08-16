extends Node2D


# Declare member variables here. Examples:
export (PackedScene) var Bolt

# var a = 2
# var b = "text"

var bolts = BoltsStore.store


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('bolt_fired', self, '_on_fired')
	Server.connect('bolt_exhausted', self, '_on_exhausted')


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_fired(ev, _dto):
	var bolt = Bolt.instance();
	var boltId = ev.get_boltId().get_guid()
	bolts.set(boltId, bolt)
	bolt.fired(ev)
	add_child(bolt)
	
func _on_exhausted(ev, _dto):
	var boltId = ev.get_boltId().get_guid()
	var bolt = bolts.get(boltId)
	if is_instance_valid(bolt):
		bolt.exhausted()
	
