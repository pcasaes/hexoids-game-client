extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const HexoidsProto = preload("res://server/HexoidsProto.gd")

const MAX = 100
const MAX_DOUBLED = MAX * 2
const DELTA_MAX = 0.1

var RNG = RandomNumberGenerator.new()

var delta_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	PlayersStore.store.connect('users_ship_moved', self, '_on_player_moved')

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_player_moved(ev, ship):
	if ev.get_reasons().find(HexoidsProto.MoveReason.BLACKHOLE_TELEPORT) > -1:
		$fg1/ColorRect.color = ship.color
		$fg1/ColorRect.color.a = 1

func _physics_process(delta):
	if !OS.has_feature('JavaScript'):
		delta_count = delta_count + delta
		if delta_count > DELTA_MAX:
			_move($stars, 8)
			_move($starsB, 7)
			delta_count = 0
			
	if $fg1/ColorRect.color.a > 0:
		$fg1/ColorRect.color.a = max(0, $fg1/ColorRect.color.a - delta)
	
func _move(sprite, factor):
	var x = sprite.position.x + max(1, RNG.randi_range(0, 10) - factor)
	var y = sprite.position.y + max(1, RNG.randi_range(0, 10) - factor)
	if x >= MAX:
		x = 0
	if y >= MAX:
		y = 0
	sprite.position.x = x
	sprite.position.y = y
