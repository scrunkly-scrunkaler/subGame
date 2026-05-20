class_name utils

## an amalgamation of [code]lerp()[/code] and [code]move_toward()[/code][br]
## [br]
## functions like [code]lerp()[/code] until the progress of [param from] toward [param to] exceeds [param threshold],[br]
## at which point functionality swaps to behave like [code]move_toward()[/code][br]
## [br]
## useful for preserving [code]lerp()[/code]'s smooth approach while avoiding its asymptotic behavior as it closes in on the target value.
static func lerp_toward(from, to, weight:float, threshold):
	if abs(to - from) > abs(to - threshold):
		var value = from + (to - from) * weight
		return value
	else:
		var value = from + (to - threshold) * weight
		return to if abs(to - value) > abs(to - from) else value

static func rangefinder(ray:RayCast3D) -> float:
		return ((ray.global_position.distance_to(ray.get_collision_point()))/ray.target_position.length()) if ray.is_colliding() else 1

## creates a custom [code]ConvexPolygonShape3D[/code] cylinder whose:[br]
## [br]
## - height is determined by [param height], measured in meters[br]
## - radius is determined by [param radius], measured in meters[br]
## - number of sides is determined by [param sides][br]
static func create_custom_cylinder_shape(height:float, radius:float, sides:int) -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	
	for i in sides:
		var angle:float = TAU * i / sides
		var x:float = cos(angle) * (radius)
		var z:float = sin(angle) * (radius)
		
		points.append(Vector3(x, -height/2, z))
		points.append(Vector3(x, height/2, z))
	shape.points = points
	return shape

## creates a custom [code]ConvexPolygonShape3D[/code] "gem" shape[br]
## a "gem" in this context is a cylinder with pointed ends, whose:[br]
## [br]
## - tip-to-tip height is determined by [param height], measured in meters[br]
## - radius is determined by [param radius], measured in meters[br]
## - number of sides is determined by [param sides][br]
## - angle of the tip at each end is determined by [param sharpness], measured in degrees with respect to a horizontal plane[br]
static func create_custom_gem_shape(height:float, radius:float, sides:int, sharpness:float) -> ConvexPolygonShape3D:
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	var apothem:float = (radius) * cos(PI/sides) # the radius of the gem as measured from the center to the middle of one of the flat sides (instead of one of the corners, which would just be width/2)
	var tip_height:float = tan(deg_to_rad(sharpness)) * apothem # the height of the just the tip by itself.
	var ring_height:float = (height/2) - tip_height # the height of the cylinder without without the tips.
	
	# the sides of the cylinder
	for i in sides:
		var angle:float = TAU * i / sides
		var x:float = cos(angle) * (radius)
		var z:float = sin(angle) * (radius)
		
		points.append(Vector3(x, -ring_height, z))
		points.append(Vector3(x, ring_height, z))
	
	# ...and add one point at each end to complete the gem
	points.append(Vector3(0, -height/2, 0))
	points.append(Vector3(0, height/2, 0))
	
	shape.points = points
	return shape
