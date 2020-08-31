extends SoundHandler


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var playerStore = PlayersStore.store

# Called when the node enters the scene tree for the first time.
func _ready():
	playerStore.connect('users_ship_destroyed', self, '_ship_destroyed')
	
func _ship_destroyed(_destroyerId, ship):
		play_in_view(true, ship.position.x, ship.position.y)
	
