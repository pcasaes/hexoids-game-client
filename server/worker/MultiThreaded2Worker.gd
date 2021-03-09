extends Node

const METRICS = false

const QUEUE_SIZE = 128

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var _thread
var _worker_in_queue
var _exit_thread = false


var total_time = 0.0
var execute_inc = 0

var next_report = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_thread = Thread.new()
	
	_worker_in_queue = FixedList.new(QUEUE_SIZE)

	_thread.start(self, "_worker_thread_function")
	print("Worker executor will run worker thread (multi threaded)")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func execute(input, worker_function, context_function):
	_worker_in_queue.push(input, worker_function, context_function)

func _worker_thread_function(_userdata):
	print("Starting worker thread (2)")
	var run = true
	var event
	while (run):
		
		while true:
			event = _worker_in_queue.pop()
			if event == null:
				OS.delay_usec(100)
				break
				
			event.execute_worker()
			#call_deferred("add_child", event.run)
			call_deferred("_execute", event)
		run = !_exit_thread
	
	print("Stopping worker thread (2)")
		

func _execute(event):
	if OS.is_debug_build():
		total_time = total_time + event.latency()
		execute_inc = execute_inc + 1

		
		event.execute_context()
		
		var t = OS.get_unix_time()
		if t > next_report && execute_inc > 0:
			print("total executions ", execute_inc, ", avg latency ", (total_time / execute_inc))
			total_time = 0.0
			execute_inc = 0
			next_report = t + 30
	else:
		event.execute_context()
	

func _exit_tree():
	_exit_thread = true
	_thread.wait_to_finish()
	
class Event:
	var input
	var worker_function
	var context_function
	
	var start_time
	
	var result = []
	
	func _init():
		result.push_back(0)
		result.push_back(0)
	
	func setup(i, w, c):
		input = i
		worker_function = w
		context_function = c
		result[0] = null
		start_time = OS.get_ticks_usec()
		result[1] = HClock.clock.clientTime()
		
	func copy(event):
		input = event.input
		worker_function = event.worker_function
		context_function = event.context_function
		result[0] = event.result[0]
		start_time = event.start_time
		result[1] = event.result[1]
		
	func execute_worker():
		result[0] = worker_function.call_func(input)
		
	func execute_context():
		context_function.call_funcv(result)
		
	func latency():
		return OS.get_ticks_usec() - start_time

class FixedList:
	var size
	var size_minus_one
	var array
	var next_read = 0
	var next_write = 0
	var actual_size = 0
	
	var max_size = 0
	
	func _init(s):
		size = s
		size_minus_one = size - 1
		array = []
		for i in size:
			array.push_back(Event.new())
			
	func _increment_write():
		var write = next_write
		next_write = (next_write + 1) & size_minus_one
		actual_size = actual_size + 1
		
		if (METRICS && actual_size > max_size):
			max_size = actual_size
			if METRICS:
				print("Event queue max size: ", max_size)

	func push_event(event):
		var ev = array[next_write]
		ev.copy(event)
		_increment_write()
		
	func push(input, worker_function, context_function):
		var event = array[next_write]
		event.setup(input, worker_function, context_function)
		_increment_write()
		
	func empty():
		return next_read == next_write
		
	func pop():
		var read = next_read
		if read == next_write:
			return null
			
		var event = array[read]
			
		actual_size = actual_size - 1
		next_read = (read + 1) & size_minus_one
		
		
		return event

