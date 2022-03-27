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
		idBytes = _config.get_value("user", "id-bytes")
		if idBytes == null:
			_generate_id()
		else:
			id = Uuid.v4(idBytes)
			idLongs = Uuid.v4Longs(idBytes)
			
		username = _config.get_value("user", "name")
	else:
		_generate_id()

func _generate_id():
	idBytes = Uuid.uuidbin()
	id = Uuid.v4(idBytes)
	idLongs = Uuid.v4Longs(idBytes)
	
	print("id ", id)
	print("id ", idLongs)
	
	_config.set_value("user", "id-bytes", idBytes)
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
	return idBytes[0] == guid[0] and idBytes[1] == guid[1] and idBytes[2] == guid[2] and idBytes[3] == guid[3] and idBytes[4] == guid[4] and idBytes[5] == guid[5] and idBytes[6] == guid[6] and idBytes[7] == guid[7] and idBytes[8] == guid[8] and idBytes[9] == guid[9] and idBytes[10] == guid[10] and idBytes[11] == guid[11] and idBytes[12] == guid[12] and idBytes[13] == guid[13] and idBytes[14] == guid[14] and idBytes[15] == guid[15]

	
	
