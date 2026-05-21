extends RigidBody3D

### player dimensions and other attributes ###

# the player's collision hull is made from a custom "gem" collision shape, which is effectively a cylinder with a pointed tip at each end.
var playerHeight:float = 1.75 				# (def: 1.75) the total height of the player's collision hull (in meters)
var playerWidth:float = 0.50 				# (def: 0.50) the total width of the player's collision hull (in meters)
var playerSides:int = 12					# (def: 12.0) the total number of sides of the player's collision hull
var playerTipAngle:float = 25				# (def: 25.0) the angle of the tips of the player's collision hull (in degrees, with respect to a horitzontal plane)

var playerMass:float = 60					# (def: 60.0) the mass of the player's rigidbody (in kilograms)

var playerCrouchHeightCoef:float = 0.60 	# (def: 0.60) the coefficient of the player's total height that the player shrinks to while crouching
var playerCrouchSpeed:float = 8				# (def: 8.00) the rate at which the player transitions from standing to crouching, and vice-versa.

var playerHeadEyesHeightCoef:float = 0.94 	# (def: 0.94) the coefficient of the player's total height upon which the camera is positioned
var playerHeadOffsetX:float = 0.00 			# (def: 0.00) the left/right offset from center upon which the camera is positioned (in meters)
var playerHeadOffsetY:float = 0.00			# (def: 0.00) the up/down offset from center upon which the camera is positioned (in meters)
var playerHeadOffsetZ:float = 0.00 			# (def: 0.00) the forward/backward offset from center upon which the camera is positioned (in meters)

var playerTPPOffsetX:float = 0.00			# (def: 0.00)
var playerTPPOffsetY:float = -0.25			# (def: -0.25)
var playerTPPOffsetZ:float = 2.00			# (def: 2.00)
var playerTPPTransitionSpeed:float = 0.1		# (def: 4.00)

var playerStepHeightCoef:float = 0.30		# (def: 0.30) the coefficient of the player's total height that the player will automatically step up or down to when encountering uneven terrain (eg. stairs)

### player physics ###

var physBaseGravity:float = 15.72			# (def: 15.72) the world gravity for the scene

var physBaseGroundSpeed:float = 5.72		# (def: 5.72) the base maximum speed the player will accelerate to under their own power while on the ground (in meters per second)
var physBaseGroundAccelCoef:float = 10		# (def: 10.0) the base accelerative rate under which the player will aproach the target speed while on the ground. Must be greater than decel value.
var physBaseGroundDecelCoef:float = 6		# (def: 6.00) the base decelerative rate under which the player will stop moving while on the ground.
var physBaseAirSpeed:float = 0.572			# (def: 0.572) the base maximum speed the player will accelerate to under their own power while in the air (in meters per second)
var physBaseAirAccelCoef:float = 4			# (def: 10.0) the base accelerative rate under which the player will aproach the target speed while in the air. Must be greater than decel value.
var physBaseAirDecelCoef:float = 0			# (def: 0.00) the base decelerative rate under which the player will stop moving while in the air.
var physBaseSwimSpeed:float = 4.00
var physBaseSwimAccelCoef:float = 5
var physBaseSwimDecelCoef:float = 5
var physBaseNoclipSpeed:float = 16.0		# (def: 16.0) the base maximum speed the player will accelerate to under their own power while noclipping (in meters per second)
var physBaseNoclipAccelCoef:float = 10		# (def: 10.0) the base accelerative rate under which the player will aproach the target speed while noclipping. Must be greater than decel value.
var physBaseNoclipDecelCoef:float = 6		# (def: 6.00) the base decelerative rate under which the player will stop moving while noclipping.

var physGroundMinDecelSpeed:float = 1.91	# (def: 1.91) the minimum speed at which the player can travel before decelerative forces become stronger than usual. Think of this as the player "catching their footing" as they slide to a stop. (in meters per second).

var physBaseJumpImpulse:float = 5.39		# (def: 5.39) the base impulse force applied to the player during a jump (in meters per second)
var physJumpCooldownTime:float = 0.15		# (def: 0.15) how long after initiating a jump before the player is able to jump again (in seconds)

var physMaxFloorAng:float = 47.5			# (def: 47.5) the maximum slope angle the player is able to walk on (in degrees)

var physSprintSpeedCoef:float = 1.40		# (def: 1.40) the coefficient of the player's base movespeed applied while the player is sprinting
var physCrouchSpeedCoef:float = 0.40		# (def: 0.40) the coefficient of the player's base movespeed applied while the player is crouching
var physWalkSpeedCoef:float = 0.50			# (def: 0.50) the coefficient of the player's base movespeed applied while the player is walking
var physSlowCrouchSpeedCoef:float = 0.25	# (def: 0.25) the coefficient of the player's base movespeed applied while the player is slow-crouching

var physStepHeightPID = PID.new(100,0,10)	# (def: 100,0,10) the player's "hover" height is managed by a PID loop. Don't touch this unless you know what you're doing.
var physStepRayHeightCoef = 2				# (def: 2.00) a coefficient used to determine the length of the player's legRays
var physStepTargetHeightCoef = 0.50			# (def: 0.50) a coefficient of the legRays' total breadth which acts as the target height for physStepHeightPID
var physStepTargetHeightTrim = 0.16			# (def: 0.16) an additional "trim" value meant to adjust for the unavoidable "slop" introduced by using a PID loop without an integral value. Added on top of physStepTargetHeightCoef.
var physSlopeRepelForce = 10				# (def: 10.0) the scaling force that pushes the player away from surfaces that exceed the player's physMaxFloorAng. 

### adjustables ###

@export_range(0.10,6.00,0.01,"or_greater") var mouseSens:float = 1.8 # (def: 1.8) mouse sensitivity (equivalent to Source 1 w/ raw input)
@export_range(50,90,1) var cameraFOV:float = 74 # (def: 74) the player viewport's field of view (measured vertically, not horizontally)
@export var autojump:bool = false # (def: false) auto-bhop while true

### input gathering ###

var inputMoveRaw:Vector3 = Vector3(0,0,0) 	# the player's raw movement inputs
var inputMoveDir2D:Vector3 = Vector3(0,0,0)	# the player's normalized movement inputs (4DoF, WASD only)
var inputMoveDir3D:Vector3 = Vector3(0,0,0)	# the player's normalized movement inputs (6DoF, WASD+up/down)
var inputSprint:bool = false
var inputCrouch:bool = false
var inputWalk:bool = false
var inputJump:bool = false
var inputNoclip:bool = false
var inputPerspectiveToggle:bool = false
var inputCamX:Vector3 = Vector3(0,0,0)
var inputCamY:Vector3 = Vector3(0,0,0)
var inputCamZ:Vector3 = Vector3(0,0,0)

### intermediaries ###

var legRays:Dictionary = {
	"IDs":([]),
	"shortest ray":1,
	"longest ray":0,
	"average height":0,
	"average normal":Vector3(0,0,0),
	"virtual normal":Vector3(0,0,0)
}
var jumping:bool = false
var time_since_last_jump:float = INF
var camCrouchProgressCoef:float = 0
var crouching:bool = false
var water_body: water

#########################################################################################################################################
### ENGINE CALLBACKS ###
#########################################################################################################################################

func _ready() -> void:
	# set gravity
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, physBaseGravity)
	# build out the player
	_player_assembly()
	return

func _unhandled_input(event:InputEvent) -> void:
	# handle mouselook, mouse capture/uncapturing
	_mouse_handler(event)
	return

func _process(delta:float) -> void:
	# nothing here for now
	_debug_tpp_transitioner(delta)
	_stance_cam_transitioner(delta)
	return

func _physics_process(delta:float) -> void:
	_input_handler()
	_stance_handler(delta)
	if inputNoclip:
		_noclip_movement_handler(delta)
	elif _is_in_water():
		_swimming_movement_handler(delta)
	elif _is_on_floor():
		_grounded_movement_handler(delta)
	else:
		_aerial_movement_handler(delta)
	return

#########################################################################################################################################
### PHYSICS PROCESS ###
#########################################################################################################################################

func _grounded_movement_handler(delta:float) -> void:
	_update_rays()
	_grounded_hover(delta)
	_grounded_slope_repel(delta)
	_grounded_jump(delta)
	_grounded_locomotion(delta)
	return

func _aerial_movement_handler(delta:float) -> void:
	_update_rays()
	_aerial_landing(delta)
	_aerial_locomotion(delta)
	return

func _swimming_movement_handler(delta:float) -> void:
	_update_rays()
	_swimming_hover(delta)
	_swimming_clamber(delta)
	_swimming_locomotion(delta)
	return

func _noclip_movement_handler(delta:float) -> void:
	%standHull.disabled = true
	%crouchHull.disabled = true
	time_since_last_jump = physJumpCooldownTime
	_noclip_locomotion(delta)
	return

#### GROUNDED ###########################################################################################################################

func _grounded_locomotion(delta:float) -> void:
	
	# first, determine the direction the player is attempting to move
	var targetDir:Vector3
	targetDir.x = (inputMoveDir2D.z * -inputCamX.z) + (inputMoveDir2D.x * inputCamX.x)
	targetDir.y = 0
	targetDir.z = (inputMoveDir2D.z * inputCamX.x) + (inputMoveDir2D.x * inputCamX.z)
	
	# then, determine the speed the player wants to move at
	var targetMoveSpeedCoef:float
	if inputSprint and not crouching:
		targetMoveSpeedCoef = physSprintSpeedCoef
	elif crouching and inputWalk:
		targetMoveSpeedCoef = physSlowCrouchSpeedCoef
	elif crouching:
		targetMoveSpeedCoef = physCrouchSpeedCoef
	elif inputWalk:
		targetMoveSpeedCoef = physWalkSpeedCoef
	else:
		targetMoveSpeedCoef = 1.0
	
	var targetSpd:float
	targetSpd = targetMoveSpeedCoef * physBaseGroundSpeed
	
	# next, we handle acceleration (locomotion) and deceleration (friction)
	var currentVelocity:Vector3
	currentVelocity.x = self.linear_velocity.x
	currentVelocity.y = self.linear_velocity.y
	currentVelocity.z = self.linear_velocity.z
	
	var currentSpd:float
	currentSpd = currentVelocity.length()
		
	var targetVelocity:Vector3
	targetVelocity = currentVelocity
	
	# friction
	if currentSpd > 0 and physBaseGroundDecelCoef > 0: # only apply friction if the player is moving and friction is set
		var decelDelta:float = max(currentSpd, physGroundMinDecelSpeed) * physBaseGroundDecelCoef * delta # determine how much the player's speed could change from deceleration this frame.
		var newSpd:float = max(currentSpd - decelDelta, 0.0) # calculate the player's new speed after applying the delta to their current speed.
		var newSpdCoef:float = newSpd/currentSpd # convert the new speed to a coefficient to skip needing to figure out the player's current heading.
		targetVelocity.x = targetVelocity.x * newSpdCoef # ]
		targetVelocity.y = targetVelocity.y * newSpdCoef # ]--- apply the new speed to the player's current velocity
		targetVelocity.z = targetVelocity.z * newSpdCoef # ]
	
	# locomotion
	if targetDir != Vector3(0,0,0) and physBaseGroundAccelCoef > 0: # only apply acceleration if the player is trying to move and can move.
		var relativeSpd:float = targetVelocity.dot(targetDir) # determine the player's current speed in relation to their desired heading
		var requiredSpd:float = targetSpd - relativeSpd # determine how much speed would be required to reach the target speed this frame
		if requiredSpd > 0 and currentSpd < targetSpd: # only try to apply an accelerative force to the player if they're not already moving at or faster than their target speed.
			var baseAccelDelta:float = physBaseGroundSpeed * physBaseGroundAccelCoef * min(targetMoveSpeedCoef,1.0) * delta # determine how much the player's speed could change from acceleration this frame
			var accelDelta:float = min(baseAccelDelta, requiredSpd) # cap the delta if it would cause the player to exceed their target speed
			targetVelocity.x = targetVelocity.x + (targetDir.x * accelDelta) # ] 
			targetVelocity.y = targetVelocity.y + (targetDir.y * accelDelta) # ]--- apply the new speed to the player's current velocity
			targetVelocity.z = targetVelocity.z + (targetDir.z * accelDelta) # ]
	
	# finally, we apply everything we calculated onto the player.
	var force:Vector3
	force.x = (targetVelocity.x - currentVelocity.x) / delta # ]
	force.y = (targetVelocity.y - currentVelocity.y) / delta # ]--- determine how much force is required to reach the target velocity from the player's current velocity this frame.
	force.z = (targetVelocity.z - currentVelocity.z) / delta # ]
	self.apply_force(force * self.mass) # apply the force, accounting for the mass of the player's body.
	return

func _grounded_jump(delta:float) -> void:
	if inputJump and not jumping and time_since_last_jump >= physJumpCooldownTime:
		time_since_last_jump = 0
		jumping = true
		var currentVelocity:Vector3
		currentVelocity = self.linear_velocity
		var virNormal:Vector3
		virNormal = _get_virtual_normal()
		var targetVelocity:Vector3
		targetVelocity.x = currentVelocity.x + (virNormal.x * physBaseJumpImpulse)
		targetVelocity.y = max(currentVelocity.y,0) + (virNormal.y * physBaseJumpImpulse) # the player 
		targetVelocity.z = currentVelocity.z + (virNormal.z * physBaseJumpImpulse)
		var force:Vector3
		force = targetVelocity - currentVelocity
		self.apply_impulse(force * self.mass)
	return

func _grounded_slope_repel(delta:float) -> void:
	var force:Vector3 = Vector3(0,0,0)
	for legRay:RayCast3D in legRays["IDs"]:
		if legRay.is_colliding():
			var normal:Vector3 = legRay.get_collision_normal()
			var slopeAngle:float = rad_to_deg(normal.angle_to(Vector3(0,1,0)))
			if slopeAngle > physMaxFloorAng and normal.y > 0: # only repel invalid floor surfaces
				var repelDir:Vector3 = Vector3(normal.x, 0, normal.z).normalized() # only repel the player away horizontally
				var contactToPlayer:Vector3 = self.global_position - legRay.get_collision_point()
				contactToPlayer.y = 0
				contactToPlayer = contactToPlayer.normalized()
				var alignment:float = max(repelDir.dot(contactToPlayer), 0) # only repel uphill surfaces (downhill are ignored)
				var steepness:float = clamp((slopeAngle - physMaxFloorAng) / (90.0 - physMaxFloorAng),0.0,1.0)
				var steepnessCoef:float = lerp(0.5,1.0,steepness) # stronger repel force for steeper surfaces
				force += repelDir * physSlopeRepelForce * alignment * steepnessCoef # each valid ray touching a surface adds its' own force
	self.apply_force(force * self.mass)
	return

func _grounded_hover(delta:float) -> void:
	var force:Vector3
	force.x = 0
	force.y = physStepHeightPID.update(physStepTargetHeightCoef+physStepTargetHeightTrim,legRays["shortest ray"],delta)
	force.z = 0
	self.apply_force(force * self.mass)
	return

### AERIAL ##############################################################################################################################

func _aerial_locomotion(delta:float) -> void:
	
	# first, determine the direction the player is attempting to move
	var targetDir:Vector3
	targetDir.x = (inputMoveDir2D.z * -inputCamX.z) + (inputMoveDir2D.x * inputCamX.x)
	targetDir.y = 0
	targetDir.z = (inputMoveDir2D.z * inputCamX.x) + (inputMoveDir2D.x * inputCamX.z)
	
	# then, determine the speed the player wants to move at (ignoring sprint, since the player cannot sprint in the air)
	var targetMoveSpeedCoef:float
	if crouching and inputWalk:
		targetMoveSpeedCoef = physSlowCrouchSpeedCoef
	elif crouching:
		targetMoveSpeedCoef = physCrouchSpeedCoef
	elif inputWalk:
		targetMoveSpeedCoef = physWalkSpeedCoef
	else:
		targetMoveSpeedCoef = 1.0
	
	var targetSpd:float
	targetSpd = targetMoveSpeedCoef * physBaseAirSpeed
	
	# next, we handle acceleration (locomotion) and deceleration (friction)
	var currentVelocity:Vector3
	currentVelocity.x = self.linear_velocity.x
	currentVelocity.y = 0
	currentVelocity.z = self.linear_velocity.z
	
	var currentSpd:float
	currentSpd = currentVelocity.length()
		
	var targetVelocity:Vector3
	targetVelocity = currentVelocity
	
	# friction (may be skipped if physBaseAirDecelCoef = 0)
	if currentSpd > 0 and physBaseAirDecelCoef > 0: # only apply friction if the player is moving and friction is set
		var decelDelta:float = currentSpd * physBaseAirDecelCoef * delta # determine how much the player's speed could change from deceleration this frame.
		var newSpd:float = max(currentSpd - decelDelta, 0.0) # calculate the player's new speed after applying the delta to their current speed.
		var newSpdCoef:float = newSpd/currentSpd # convert the new speed to a coefficient to skip needing to figure out the player's current heading.
		targetVelocity.x = targetVelocity.x * newSpdCoef # ]
		targetVelocity.z = targetVelocity.z * newSpdCoef # ]--- apply the new speed to the player's current velocity
	
	# locomotion
	if targetDir != Vector3(0,0,0) and physBaseAirAccelCoef > 0: # only apply acceleration if the player is trying to move and can move.
		var relativeSpd:float = targetVelocity.dot(targetDir) # determine the player's current speed in relation to their desired heading
		var requiredSpd:float = targetSpd - relativeSpd # determine how much speed would be required to reach the target speed this frame
		if requiredSpd > 0: # only try to apply an accerlative force to the player if they're not already moving at or faster than their target speed.
			var baseAccelDelta:float = physBaseGroundSpeed * physBaseAirAccelCoef * min(targetMoveSpeedCoef,1.0) * delta # determine how much the player's speed could change from acceleration this frame
			var accelDelta:float = min(baseAccelDelta, requiredSpd) # cap the delta if it would cause the player to exceed their target speed
			targetVelocity.x = targetVelocity.x + (targetDir.x * accelDelta) # ]
			targetVelocity.z = targetVelocity.z + (targetDir.z * accelDelta) # ]--- apply the new speed to the player's current velocity
	
	# finally, we apply everything we calculated onto the player.
	var force:Vector3
	force.x = (targetVelocity.x - currentVelocity.x) / delta # ]
	force.y = 0                                              # ]--- determine how much force is required to reach the target velocity from the player's current velocity this frame.
	force.z = (targetVelocity.z - currentVelocity.z) / delta # ]
	self.apply_force(force * self.mass) # apply the force, accounting for the mass of the player's body.
	return

func _aerial_landing(delta:float) -> void:
	if jumping and legRays["shortest ray"] < (physStepTargetHeightCoef+physStepTargetHeightTrim) and time_since_last_jump >= physJumpCooldownTime:
		jumping = false
	time_since_last_jump += delta
	time_since_last_jump = clamp(time_since_last_jump,0,physJumpCooldownTime)
	return

### SWIMMING ############################################################################################################################

func _swimming_locomotion(delta:float) -> void:
	
	# first, determine the direction the player is attempting to move
	var targetDir:Vector3
	targetDir.x = (inputMoveDir3D.z * inputCamZ.x) + (inputMoveDir3D.x * inputCamX.x) + (inputMoveDir3D.y * inputCamY.x)
	targetDir.y = (inputMoveDir3D.z * inputCamZ.y) + (inputMoveDir3D.x * inputCamX.y) + (inputMoveDir3D.y * inputCamY.y)
	targetDir.z = (inputMoveDir3D.z * inputCamZ.z) + (inputMoveDir3D.x * inputCamX.z) + (inputMoveDir3D.y * inputCamY.z)
	
	# then, determine the speed the player wants to move at (no crouch because that's how you descend in noclip)
	var targetMoveSpeedCoef:float
	if inputSprint:
		targetMoveSpeedCoef = physSprintSpeedCoef
	elif inputWalk:
		targetMoveSpeedCoef = physWalkSpeedCoef
	else:
		targetMoveSpeedCoef = 1.0
	
	var targetSpd:float
	targetSpd = targetMoveSpeedCoef * physBaseSwimSpeed
	
	# next, we handle acceleration (locomotion) and deceleration (friction)
	var currentVelocity:Vector3
	currentVelocity.x = self.linear_velocity.x
	currentVelocity.y = self.linear_velocity.y
	currentVelocity.z = self.linear_velocity.z
	
	var currentSpd:float
	currentSpd = currentVelocity.length()
		
	var targetVelocity:Vector3
	targetVelocity = currentVelocity
	
	# friction (may be skipped if physBaseAirDecelCoef = 0)
	if currentSpd > 0 and physBaseSwimDecelCoef > 0: # only apply friction if the player is moving and friction is set
		var decelDelta:float = currentSpd * physBaseSwimDecelCoef * delta # determine how much the player's speed could change from deceleration this frame.
		var newSpd:float = max(currentSpd - decelDelta, 0.0) # calculate the player's new speed after applying the delta to their current speed.
		var newSpdCoef:float = newSpd/currentSpd # convert the new speed to a coefficient to skip needing to figure out the player's current heading.
		targetVelocity.x = targetVelocity.x * newSpdCoef # ]
		targetVelocity.y = targetVelocity.y * newSpdCoef # ]
		targetVelocity.z = targetVelocity.z * newSpdCoef # ]--- apply the new speed to the player's current velocity
	
	# locomotion
	if targetDir != Vector3(0,0,0) and physBaseSwimAccelCoef > 0: # only apply acceleration if the player is trying to move and can move.
		var relativeSpd:float = targetVelocity.dot(targetDir) # determine the player's current speed in relation to their desired heading
		var requiredSpd:float = targetSpd - relativeSpd # determine how much speed would be required to reach the target speed this frame
		if requiredSpd > 0: # only try to apply an accerlative force to the player if they're not already moving at or faster than their target speed.
			var baseAccelDelta:float = physBaseSwimSpeed * physBaseSwimAccelCoef * min(targetMoveSpeedCoef,1.0) * delta # determine how much the player's speed could change from acceleration this frame
			var accelDelta:float = min(baseAccelDelta, requiredSpd) # cap the delta if it would cause the player to exceed their target speed
			targetVelocity.x = targetVelocity.x + (targetDir.x * accelDelta) # ]
			targetVelocity.y = targetVelocity.y + (targetDir.y * accelDelta) # ]
			targetVelocity.z = targetVelocity.z + (targetDir.z * accelDelta) # ]--- apply the new speed to the player's current velocity
	
	# finally, we apply everything we calculated onto the player.
	var force:Vector3
	force.x = (targetVelocity.x - currentVelocity.x) / delta                     # ]
	force.y = ((targetVelocity.y - currentVelocity.y) / delta) + physBaseGravity * 0.9 # ]--- determine how much force is required to reach the target velocity from the player's current velocity this frame.
	force.z = (targetVelocity.z - currentVelocity.z) / delta                     # ]
	self.apply_force(force * self.mass) # apply the force, accounting for the mass of the player's body.
	return

func _swimming_hover(delta:float) -> void:
	var force:Vector3
	force.x = 0
	force.y = max(physStepHeightPID.update(physStepTargetHeightCoef+physStepTargetHeightTrim,legRays["shortest ray"],delta),0)
	force.z = 0
	self.apply_force(force * self.mass)
	return

func _swimming_clamber(delta:float) -> void:
	#var clamberableSurface:bool = false
	#
	# some bullshit involving `PhysicsServer3D.body_test_motion`
	#
	#if clamberableSurface:
	#	var force:Vector3
	#	force.x = 0
	#	force.y = 0
	#	force.z = 0
	#	self.apply_force(force * self.mass)
	return

### NOCLIP ##############################################################################################################################

func _noclip_locomotion(delta:float) -> void:
	
	# first, determine the direction the player is attempting to move
	var targetDir:Vector3
	targetDir.x = (inputMoveDir3D.z * inputCamZ.x) + (inputMoveDir3D.x * inputCamX.x) + (inputMoveDir3D.y * inputCamY.x)
	targetDir.y = (inputMoveDir3D.z * inputCamZ.y) + (inputMoveDir3D.x * inputCamX.y) + (inputMoveDir3D.y * inputCamY.y)
	targetDir.z = (inputMoveDir3D.z * inputCamZ.z) + (inputMoveDir3D.x * inputCamX.z) + (inputMoveDir3D.y * inputCamY.z)
	
	# then, determine the speed the player wants to move at (no crouch because that's how you descend in noclip)
	var targetMoveSpeedCoef:float
	if inputSprint:
		targetMoveSpeedCoef = physSprintSpeedCoef
	elif inputWalk:
		targetMoveSpeedCoef = physSlowCrouchSpeedCoef
	else:
		targetMoveSpeedCoef = 1.0
	
	var targetSpd:float
	targetSpd = targetMoveSpeedCoef * physBaseNoclipSpeed
	
	# next, we handle acceleration (locomotion) and deceleration (friction)
	var currentVelocity:Vector3
	currentVelocity.x = self.linear_velocity.x
	currentVelocity.y = self.linear_velocity.y
	currentVelocity.z = self.linear_velocity.z
	
	var currentSpd:float
	currentSpd = currentVelocity.length()
		
	var targetVelocity:Vector3
	targetVelocity = currentVelocity
	
	# friction (may be skipped if physBaseAirDecelCoef = 0)
	if currentSpd > 0 and physBaseNoclipDecelCoef > 0: # only apply friction if the player is moving and friction is set
		var decelDelta:float = currentSpd * physBaseNoclipDecelCoef * delta # determine how much the player's speed could change from deceleration this frame.
		var newSpd:float = max(currentSpd - decelDelta, 0.0) # calculate the player's new speed after applying the delta to their current speed.
		var newSpdCoef:float = newSpd/currentSpd # convert the new speed to a coefficient to skip needing to figure out the player's current heading.
		targetVelocity.x = targetVelocity.x * newSpdCoef # ]
		targetVelocity.y = targetVelocity.y * newSpdCoef # ]
		targetVelocity.z = targetVelocity.z * newSpdCoef # ]--- apply the new speed to the player's current velocity
	
	# locomotion
	if targetDir != Vector3(0,0,0) and physBaseNoclipAccelCoef > 0: # only apply acceleration if the player is trying to move and can move.
		var relativeSpd:float = targetVelocity.dot(targetDir) # determine the player's current speed in relation to their desired heading
		var requiredSpd:float = targetSpd - relativeSpd # determine how much speed would be required to reach the target speed this frame
		if requiredSpd > 0: # only try to apply an accerlative force to the player if they're not already moving at or faster than their target speed.
			var baseAccelDelta:float = physBaseNoclipSpeed * physBaseNoclipAccelCoef * min(targetMoveSpeedCoef,1.0) * delta # determine how much the player's speed could change from acceleration this frame
			var accelDelta:float = min(baseAccelDelta, requiredSpd) # cap the delta if it would cause the player to exceed their target speed
			targetVelocity.x = targetVelocity.x + (targetDir.x * accelDelta) # ]
			targetVelocity.y = targetVelocity.y + (targetDir.y * accelDelta) # ]
			targetVelocity.z = targetVelocity.z + (targetDir.z * accelDelta) # ]--- apply the new speed to the player's current velocity
	
	# finally, we apply everything we calculated onto the player.
	var force:Vector3
	force.x = (targetVelocity.x - currentVelocity.x) / delta                     # ]
	force.y = ((targetVelocity.y - currentVelocity.y) / delta) + physBaseGravity # ]--- determine how much force is required to reach the target velocity from the player's current velocity this frame.
	force.z = (targetVelocity.z - currentVelocity.z) / delta                     # ]
	self.apply_force(force * self.mass) # apply the force, accounting for the mass of the player's body.
	
	return

### SHARED FUNCTIONS ####################################################################################################################

func _update_rays() -> void:
	var minHeight:float = 1
	var maxHeight:float = 0
	var avgHeight:float = 0
	var avgNormal:Vector3 = Vector3(0,0,0)
	var validRays:float = 0
	for legRay in legRays["IDs"]:
		var normal:float = rad_to_deg(legRay.get_collision_normal().angle_to(Vector3(0,1,0)))
		if legRay.is_colliding() and normal <= physMaxFloorAng: # do not consider rays that aren't colliding or valid.
			validRays += 1
			minHeight = min(utils.rangefinder(legRay),minHeight)
			maxHeight = max(utils.rangefinder(legRay),maxHeight)
			avgHeight = avgHeight + utils.rangefinder(legRay)
			avgNormal = avgNormal + legRay.get_collision_normal()
	avgHeight = avgHeight / validRays
	avgNormal = avgNormal / validRays
	legRays["shortest ray"] = minHeight
	legRays["longest ray"] = maxHeight
	legRays["average height"] = avgHeight
	legRays["average normal"] = avgNormal
	#print(snapped(legRays["shortest ray"],0.01))
	return

func _is_on_floor() -> bool:
	if jumping:
		return false
	for legRay in legRays["IDs"]:
		var floorNormal:float = rad_to_deg(legRay.get_collision_normal().angle_to(Vector3(0,1,0)))
		if legRay.is_colliding() and floorNormal <= physMaxFloorAng:
			return true
	return false

func _is_in_water() -> bool:
	#temp
	if %waterProbe.global_position.y < 0.5:
		return true
	return false

func _get_virtual_normal() -> Vector3:
	
	# first, gather each valid collision point into a new array
	var points:Array[Vector3] = []
	for legRay:RayCast3D in legRays["IDs"]:
		if legRay.is_colliding():
			points.append(to_local(legRay.get_collision_point()))
	if points.size() < 3: # if there aren't enough valid points, return the next best thing instead.
		return legRays["average normal"]
	
	# then, find the center of all the valid collision points
	var avg:Vector3 = Vector3(0,0,0)
	for point:Vector3 in points:
		avg += point
	avg /= points.size()
	
	# next, use least-squares to approximate the plane beneath the player using the collision points and the average we calculated.
	var xx:float = 0
	var xz:float = 0
	var zz:float = 0
	var xy:float = 0
	var zy:float = 0
	for point in points:
		var x:float = point.x - avg.x
		var y:float = point.y - avg.y
		var z:float = point.z - avg.z
		xx += x * x
		xz += x * z
		zz += z * z
		xy += x * y
		zy += z * y
	
	var determinant:float = (xx * zz) - (xz * xz)	
	var a:float = ((xy * zz) - (zy * xz)) / determinant
	var b:float = ((zy * xx) - (xy * xz)) / determinant
	
	# arrange the results into a normal local to the player
	var localNormal:Vector3 = Vector3(-a, 1, -b).normalized()
	
	# convert the normal back to world space
	return (global_basis * localNormal).normalized()

### STANCE MANAGEMENT ###################################################################################################################

func _stance_handler(delta:float) -> void:
	
	if inputNoclip or _is_in_water():
		crouching = false
	elif inputCrouch:
		crouching = true
	elif _can_stand():
		crouching = false
	
	if camCrouchProgressCoef < 1:
		%standHull.disabled = false
		%crouchHull.disabled = true
	else:
		%standHull.disabled = true
		%crouchHull.disabled = false
		
	%stance.text = "Stance: %s" % _get_current_stance()
	return

func _get_current_stance() -> String:
	if inputNoclip:
		return "noclipping"
	elif _is_in_water():
		return "swimming"
	elif jumping:
		return "jumping"
	elif camCrouchProgressCoef == 1:
		if inputWalk:
			return "slow-crouching"
		else:
			return "crouching"
	elif inputWalk:
		return "walking"
	elif inputSprint:
		return "sprinting"
	return "standing"
	
func _can_stand() -> bool:
	return not %uncrouchHull.is_colliding()

### INPUT ###############################################################################################################################

func _input_handler() -> void:
	# WASD
	var inputFWDBCK = Input.get_axis("Forward","Backward")
	var inputLFTRGT = Input.get_axis("Left","Right")
	var inputUPDOWN = Input.get_axis("Crouch","Jump")
	
	inputMoveRaw = Vector3(inputLFTRGT,inputUPDOWN,inputFWDBCK)
	inputMoveDir2D = Vector3(inputLFTRGT,0,inputFWDBCK).normalized() # for 2D movement (grounded, aerial)
	inputMoveDir3D = Vector3(inputLFTRGT,inputUPDOWN,inputFWDBCK).normalized() # for 3d movement (noclip, swimming)
	
	# jumping
	if autojump:
		inputJump = Input.is_action_pressed("Jump")
	else:
		inputJump = Input.is_action_just_pressed("Jump")
	
	#stance inputs
	inputSprint = Input.is_action_pressed("Sprint") and not Input.is_action_pressed("Walk") and not Input.is_action_pressed("Crouch") and inputFWDBCK == -1
	inputCrouch = Input.is_action_pressed("Crouch")
	inputWalk = Input.is_action_pressed("Walk")
	
	
	# noclip toggle
	if Input.is_action_just_pressed("Noclip"):
		inputNoclip = not inputNoclip
	
	if Input.is_action_just_pressed("DebugPerspectiveToggle"):
		inputPerspectiveToggle = not inputPerspectiveToggle
	
	# camera direction
	inputCamX = %headEyes.global_basis.x
	inputCamY = %headEyes.global_basis.y
	inputCamZ = %headEyes.global_basis.z
	return

#########################################################################################################################################
### PROCESS ###
#########################################################################################################################################

func _stance_cam_transitioner(delta:float) -> void:
	var camStandingHeight = playerHeight * playerHeadEyesHeightCoef
	var camCrouchAdjust = playerHeight - (playerHeight * playerCrouchHeightCoef)
	var camCrouchingHeight = camStandingHeight - camCrouchAdjust
	if crouching:
		%headYaw.position.y = utils.lerp_toward(%headYaw.position.y,camCrouchingHeight,playerCrouchSpeed*delta,camCrouchingHeight+(camCrouchAdjust*0.10))
	else:
		%headYaw.position.y = utils.lerp_toward(%headYaw.position.y,camStandingHeight,playerCrouchSpeed*delta,camStandingHeight-(camCrouchAdjust*0.10))
	camCrouchProgressCoef = snapped(inverse_lerp(camStandingHeight,camCrouchingHeight,%headYaw.position.y),0.01)
	return

func _debug_tpp_transitioner(delta:float) -> void:
	var playerTPPOffset:Vector3 = Vector3(playerTPPOffsetX,playerTPPOffsetY,playerTPPOffsetZ)
	if inputPerspectiveToggle:
		%headEyes.position = utils.lerp_toward(%headEyes.position,playerTPPOffset,playerTPPTransitionSpeed,playerTPPOffset*0.9)
	else:
		%headEyes.position = utils.lerp_toward(%headEyes.position,Vector3.ZERO,playerTPPTransitionSpeed,playerTPPOffset*0.1)
	return

#########################################################################################################################################
### UNHANDLED INPUT ###
#########################################################################################################################################

func _mouse_handler(event:InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			%headYaw.rotation_degrees.y += (-event.relative.x * mouseSens)/45.457 # arbitrary number to force mouse sens figures to match source 1's
			%headPitch.rotation_degrees.x += (-event.relative.y * mouseSens)/45.457 # arbitrary number to force mouse sens figures to match source 1's
			%headPitch.rotation_degrees.x = clamp(%headPitch.rotation_degrees.x,-90,90)
			
		if event.is_action_pressed("Escape"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return

#########################################################################################################################################
### READY ###
#########################################################################################################################################

func _player_assembly() -> void:
	
	self.mass = playerMass
	%headEyes.fov = cameraFOV
	
	# create and position the player's collision hulls
	var apothem:float = (playerWidth / 2) * cos(PI / playerSides)
	var tip_height:float = tan(deg_to_rad(playerTipAngle)) * apothem
	var standHullHeight = (playerHeight) - (playerHeight * playerStepHeightCoef) + tip_height
	var crouchHullHeight = (playerHeight * playerCrouchHeightCoef) - (playerHeight * playerStepHeightCoef) + tip_height
	%standHull.disabled = false
	%standHull.shape = utils.create_custom_gem_shape(
		standHullHeight,
		playerWidth / 2,
		playerSides,
		playerTipAngle
	)
	%standHull.position.x = 0
	%standHull.position.y = (playerHeight * playerStepHeightCoef) + (standHullHeight  / 2) - tip_height
	%standHull.position.z = 0
	
	%crouchHull.disabled = true
	%crouchHull.shape = utils.create_custom_gem_shape(
		crouchHullHeight,
		playerWidth / 2,
		playerSides,
		playerTipAngle
	)
	%crouchHull.position.x = 0
	%crouchHull.position.y = (playerHeight * playerStepHeightCoef) + (crouchHullHeight / 2) - tip_height
	%crouchHull.position.z = 0
	
	%uncrouchHull.shape.height = playerHeight - (playerHeight * playerCrouchHeightCoef) + tip_height
	%uncrouchHull.shape.radius = (playerWidth / 2) - 0.03
	%uncrouchHull.position.x = 0
	%uncrouchHull.position.y = playerHeight - (%uncrouchHull.shape.height / 2)
	%uncrouchHull.position.z = 0
	
	# position the player's head and eyes.
	%headYaw.position.x = 0
	%headYaw.position.y = playerHeight * playerHeadEyesHeightCoef
	%headYaw.position.z = 0
	
	%headPitch.position.x = playerHeadOffsetX
	%headPitch.position.y = 0
	%headPitch.position.z = 0
	
	%headEyes.position.x = 0
	%headEyes.position.y = playerHeadOffsetY
	%headEyes.position.z = playerHeadOffsetZ
	
	%underwaterEffector.position.x = 0
	%underwaterEffector.position.y = 0
	%underwaterEffector.position.z = -(playerWidth / 2)
	
	# create, position, and catalog the player's legRays
	_create_ray_ring(
		"legRay",
		%standHull,
		(playerHeight * playerStepHeightCoef) * physStepRayHeightCoef,
		standHullHeight,
		playerWidth / 2,
		playerSides,
		playerTipAngle
	)
	return

### TERTIARY FUNCTIONS ##################################################################################################################

func _create_ray_ring(
	name:String, 	# the naming convention of the downward-facing raycasts
	parent:Node3D, 	# the parent shape of the downward-facing raycasts
	length:float, 	# the length of the downward-facing raycasts
	height:float, 	# the height of the gem-shape
	radius:float, 	# the radius of the gem-shape
	sides:int, 		# the number of sides of the gem-shape
	sharpness:float	# the sharpness of the gem-shape
) -> void:
	var apothem:float = radius * cos(PI / sides)
	var tip_height:float = tan(deg_to_rad(sharpness)) * apothem
	var ring_height:float = (height / 2) - tip_height
	
	var ray_dict:Dictionary = get("%ss" % name)
	
	for i in sides:
		var angle:float = TAU * i / sides
		var x:float = cos(angle) * radius
		var z:float = sin(angle) * radius
		
		var ray := RayCast3D.new()
		ray.enabled = true
		ray.hit_from_inside = false
		ray.process_mode = Node.PROCESS_MODE_ALWAYS
		ray.name = "%s%s" % [name, i]
		ray.position = Vector3(x, -ring_height, z)
		ray.target_position = Vector3(0, -length, 0)
		
		parent.add_child(ray)
		ray_dict["IDs"].append(ray)
	return
