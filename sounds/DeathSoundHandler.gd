extends SoundHandler


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const death_res = preload("res://sounds/samples/death_res.tscn")

var playerStore = PlayersStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	type = death_res
	playerStore.connect('users_ship_destroyed', self, '_ship_destroyed')
	
func _ship_destroyed(_destroyerId, ship):
		play_in_view(true, ship.position.x, ship.position.y)
	
