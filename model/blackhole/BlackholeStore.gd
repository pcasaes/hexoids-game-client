extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var runUntil = -1

var event

signal blackhole_event

var started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('mass_collapsed_into_blackHole', self, '_on_mass_collapsed_into_blackHole')

func _on_mass_collapsed_into_blackHole(ev, _dto):
	event = ev
	runUntil = ev.get_endTimestamp()
	_set_enable(true)

func _set_enable(en):
	if started != en:
		started = en
		emit_signal("blackhole_event", event, en)

func _physics_process(_delta):
	if started:
		var now = HClock.clock.gameTime()
		if now >= runUntil:
			_set_enable(false)
