class_name water
extends MeshInstance3D

func _process(delta:float) -> void:
	%waterMesh.get_active_material(0).set_shader_parameter("GLOBAL_TIME", GLOBAL_TIME.time)
	return

@export var sea_height: float = 1.3
@export var sea_choppy: float = 4.0
@export var sea_speed: float = 1.5
@export var sea_freq: float = 0.08
@export var height_offset: float = 0
@export var water_level_fudge: float = 0

const ITER_GEOMETRY: int = 3

func get_surface_y_at_position(world_position: Vector3) -> float:
	var time: float = GLOBAL_TIME.time
	
	var uv := Vector2(world_position.x, world_position.z)
	uv.x *= 0.75
	
	var freq: float = sea_freq
	var amp: float = sea_height
	var chop: float = sea_choppy
	var height: float = 0
	
	for i: int in range(ITER_GEOMETRY):
		var time_offset := Vector2(time * sea_speed, time * sea_speed)
		
		var d: float = _sea_octave((uv + time_offset) * freq, chop)
		d += _sea_octave((uv - time_offset) * freq, chop)
		
		height += d * amp
		
		uv = _octave_transform(uv)
		freq *= 1.9
		amp *= 0.22
		chop = lerpf(chop, 1.0, 0.2)
	
	return height + height_offset + water_level_fudge

func _octave_transform(uv: Vector2) -> Vector2:
	return Vector2(
		uv.x * 1.6 + uv.y * -1.2,
		uv.x * 1.2 + uv.y * 1.6
	)

func _sea_octave(uv: Vector2, choppy: float) -> float:
	uv += Vector2(_noise(uv), _noise(uv))
	
	var wv := Vector2(
		1.0 - abs(sin(uv.x)),
		1.0 - abs(sin(uv.y))
	)
	
	var swv := Vector2(
		abs(cos(uv.x)),
		abs(cos(uv.y))
	)
	
	wv = Vector2(
		lerpf(wv.x, swv.x, wv.x),
		lerpf(wv.y, swv.y, wv.y)
	)
	
	return pow(1.0 - pow(wv.x * wv.y, 0.65), choppy)

func _hash12(p: Vector2) -> float:
	var x: int = int(p.x) * 1597334677
	var y: int = int(p.y) * 3812015801
	var n: int = (x ^ y) * 1597334677
	
	return float(n & 0xFFFFFFFF) / 4294967295.0


func _noise(p: Vector2) -> float:
	var i := Vector2(floor(p.x), floor(p.y))
	var f := Vector2(p.x - i.x, p.y - i.y)
	
	var u := Vector2(
		f.x * f.x * (3.0 - 2.0 * f.x),
		f.y * f.y * (3.0 - 2.0 * f.y)
	)
	
	var a: float = _hash12(i + Vector2(0,0))
	var b: float = _hash12(i + Vector2(1,0))
	var c: float = _hash12(i + Vector2(0,1))
	var d: float = _hash12(i + Vector2(1,1))
	
	var x1: float = lerpf(a, b, u.x)
	var x2: float = lerpf(c, d, u.x)
	
	return -1.0 + 2.0 * lerpf(x1, x2, u.y)
