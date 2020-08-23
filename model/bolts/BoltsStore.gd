extends Node

const Bolt = preload("res://model/bolts/Bolt.tscn")

var store = BoltsStore.new() setget ,get_store


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('bolt_fired', self, '_on_fired')
	Server.connect('bolt_exhausted', self, '_on_exhausted')


func get_store():
	return store
	
func _on_fired(ev, _dto):
	var bolt = Bolt.instance();
	var boltId = ev.get_boltId().get_guid()
	store.set(boltId, bolt)
	bolt.fired(ev)
	store.emit_signal("bolt_created", bolt)
	
func _on_exhausted(ev, _dto):
	var boltId = ev.get_boltId().get_guid()
	var bolt = store.get(boltId)
	if is_instance_valid(bolt):
		bolt.exhausted()
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


class BoltsStore:
	signal bolt_created
	var bolts = {}
	
	func set(guid, p):
		bolts[guid] = p
		
	func remove(guid):
		bolts.erase(guid)
		
	func get(uuid):
		return bolts.get(uuid)
		
	func all():
		return bolts.values()
