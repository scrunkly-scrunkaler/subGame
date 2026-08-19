class_name PID

var proportional:float = 0
var integral:float = 0
var derivative:float = 0

var error_time:float = 0
var previous_error:float = 0

func _init(p:float, i:float, d:float) -> void:
	proportional = p
	integral = i
	derivative = d

func update(to:float, from:float, delta:float) -> float:
	var error = to - from
	error_time += error * delta
	
	var error_rate:float = (error - previous_error) / delta
	previous_error = error
	
	return (proportional * error) + (integral * error_time) + (derivative * error_rate)
