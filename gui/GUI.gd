extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

const HexoidsProto = preload("res://server/HexoidsProto.gd")

var RNG = RandomNumberGenerator.new()

var signalLossUntil = -1

var signalStrength = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('server_connected', self, '_on_server_connected')
	PlayersStore.store.connect('users_ship_moved', self, '_on_player_moved')
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	_on_resize()

func _on_resize():
	self.rect_min_size = Vector2(0, get_viewport_rect().size.y-16)
	$HUD/Left.rect_min_size.x = get_viewport_rect().size.x / 2 - 260
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if signalStrength >= 1 or signalLossUntil < HClock.clock.gameTime():
		$HUD.modulate.a = 1
		signalStrength = 1.0
	elif RNG.randi_range(0, 1) == 0:
		$HUD.modulate.a = RNG.randf_range(signalStrength, 1)

func _on_server_connected():
	$HUD.visible = true

func _on_player_moved(ev, ship):
	if ev.get_reasons().find(HexoidsProto.MoveReason.BLACKHOLE_PULL) > -1:
		signalLossUntil = ev.get_timestamp() + 1000
		var s = 1.0 - min(1, max(0, (ev.get_velocity() - 0.025) * 10.0))
		signalStrength = s * s
