extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var rng = RandomNumberGenerator.new()

var currentScale = 1.0

var runUntil = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.connect('mass_collapsed_into_blackHole', self, '_on_mass_collapsed_into_blackHole')
	_set_enable(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_mass_collapsed_into_blackHole(ev, _dto):
	runUntil = ev.get_endTimestamp()
	
	var x = HexoidsConfig.world.xToView(ev.get_x())
	var y = HexoidsConfig.world.yToView(ev.get_y())
		
	position = Vector2(x, y)
	
	_set_enable(true)
	
func _set_enable(en):
	visible = en
	set_process(en)
	set_physics_process(en)

func _physics_process(_delta):
	var now = HClock.clock.gameTime()
	if now >= runUntil:
		_set_enable(false)
	else:
		var m
		var x
		if currentScale > 0.85:
			m = -0.06
			x = 0.05
		else:
			m = -0.05
			x = 0.06
			
		var rd = rng.randf_range(m, x)
		currentScale = max(0.7, min(1.0, currentScale + rd))
		var a = rng.randf_range(0.2, 0.9)
		var c = rng.randi_range(-1, HexoidsColors.size())
		var color
		if c < 0:
			color = Color(1, 1, 1)
		else:
			color = HexoidsColors.get(c).getColor()
		$accretion.set_scale(Vector2(currentScale, currentScale))
		$accretion.modulate = color
		$accretion.modulate.a = a
