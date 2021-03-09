extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var total_time = 0.0
var execute_inc = 0

var next_report = 0

var context_arg = []

# Called when the node enters the scene tree for the first time.
func _ready():
	context_arg.push_back(0)
	context_arg.push_back(0)
	print("Worker executor will run in main thread (single threaded)")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func execute(input, worker_function, context_function):
	if OS.is_debug_build():
		var s = OS.get_ticks_usec()
		var r = worker_function.call_func(input)
		var e = OS.get_ticks_usec()
		
		total_time = total_time + (e-s)
		execute_inc = execute_inc + 1

		context_arg[0] = r
		context_arg[1] = HClock.clock.clientTime()
		context_function.call_funcv(context_arg)
		
		var t = OS.get_unix_time()
		if t > next_report:
			print("total executions ", execute_inc, ", avg latency ", (total_time / execute_inc))
			total_time = 0.0
			execute_inc = 0
			next_report = t + 30
	else:
		var r = worker_function.call_func(input)
		context_arg[0] = r
		context_arg[1] = HClock.clock.clientTime()
		context_function.call_funcv(context_arg)
		
