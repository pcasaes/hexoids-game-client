extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const CONFIG_FILE = "user://user.cfg"

var idBytes
var id
var idLongs
var username  setget set_username, get_username
var _config

# Called when the node enters the scene tree for the first time.
func _ready():
	_config = ConfigFile.new()
	var err = _config.load(CONFIG_FILE)
	if err == OK:
		idBytes = PoolByteArray(_config.get_value("user", "id-bytes"))
		if idBytes == null:
			_generate_id()
		else:
			id = Uuid.v4(idBytes)
			idLongs = Uuid.v4Longs(idBytes)
			
		username = _config.get_value("user", "name")
	else:
		_generate_id()

func _generate_id():
	var bytes = Uuid.uuidbin()
	idBytes = PoolByteArray(bytes)
	id = Uuid.v4(idBytes)
	idLongs = Uuid.v4Longs(idBytes)
	
	print("id ", id)
	print("id ", idLongs)
	
	_config.set_value("user", "id-bytes", bytes)
	_config.save(CONFIG_FILE)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_username(n):
	if n != username:
		username = n
		_config.set_value("user", "name", username)
		_config.save(CONFIG_FILE)	

func get_username():
	return username

func is_user_from_guid(guid):
	return idBytes == guid
	
	
