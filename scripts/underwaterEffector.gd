extends MeshInstance3D

func _process(delta:float) -> void:
	if %underwaterEffector.get_active_material(0) != null:
		%underwaterEffector.get_active_material(0).set_shader_parameter("GLOBAL_TIME", GLOBAL_TIME.time)
	return
