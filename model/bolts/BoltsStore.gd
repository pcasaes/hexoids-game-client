extends Node

const Bolt = preload("res://model/bolts/Bolt.tscn")

var store = BoltsStore.new() setget ,get_store

var pool = ObjectPool.factory.newPool(1024, Bolt)


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('bolt_fired', self, '_on_fired')
	Server.connect('bolt_exhausted', self, '_on_exhausted')
	Server.connect('server_disconnected', self, '_on_server_disconnected')


func get_store():
	return store
	
func _on_fired(ev, _dto):
	var bolt = pool.borrowObject();
	bolt.visible = true
	var boltId = ev.get_boltId().get_guid()
	bolt.boltId = boltId
	store.set(boltId, bolt)
	bolt.fired(ev)
	store.emit_signal("bolt_created", bolt)
	
func _on_exhausted(ev, _dto):
	var boltId = ev.get_boltId().get_guid()
	var bolt = store.get(boltId)
	if bolt != null:
		_destroy(bolt)

func _on_server_disconnected():
	for bolt in store.all():
		_destroy(bolt)

func _destroy(bolt):
	store.emit_signal("bolt_destroyed", bolt)
	pool.returnObject(bolt)
	store.remove(bolt.boltId)
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


class BoltsStore:
	signal bolt_created
	signal bolt_destroyed
	

	var bolts = {}
	
	func set(guid, p):
		bolts[guid] = p
		
	func remove(guid):
		bolts.erase(guid)
		
	func get(uuid):
		return bolts.get(uuid)
		
	func all():
		return bolts.values()
