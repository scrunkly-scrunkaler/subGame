extends MeshInstance3D

func _process(delta:float) -> void:
	%waterMesh.get_active_material(0).set_shader_parameter("GLOBAL_TIME", GLOBAL_TIME.time)
	return
