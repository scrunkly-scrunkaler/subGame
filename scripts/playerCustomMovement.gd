extends RigidBody3D

### player dimensions and other attributes ###

# the player's collision hull is made from a custom "gem" collision shape, which is effectively a cylinder with a pointed tip at each end.
var playerHeight:float = 1.75 				# (def: 1.75) the total height of the player's collision hull (in meters)
var playerWidth:float = 0.50 				# (def: 0.50) the total width of the player's collision hull (in meters)
var playerMass:float = 60					# (def: 60.0) kilograms

var playerCrouchHeightCoef:float = 0.60 	# (def: 0.60) the coefficient of the player's total height that the player shrinks to while crouching

var playerHeadEyesHeightCoef:float = 0.94 	# (def: 0.94) the coefficient of the player's total height upon which the camera is positioned
var playerHeadOffsetX:float = 0.00 			# (def: 0.00) the left/right offset from center upon which the camera is positioned (in meters)
var playerHeadOffsetY:float = 0.00			# (def: 0.00) the up/down offset from center upon which the camera is positioned (in meters)
var playerHeadOffsetZ:float = 0.00 			# (def: 0.00) the forward/backward offset from center upon which the camera is positioned (in meters)

var playerStepHeightCoef:float = 0.30		# (def: 0.30) the coefficient of the player's total height that the player will automatically step up or down to when encountering uneven terrain (eg. stairs)

### player physics ###

var physBaseGravity:float = 15.72			# (def: 15.72)

var physGroundMinDecelSpeed:float = 1.91	# (def: 1.91) the minimum speed at which the player can travel before decelerative forces become stronger than usual. Think of this as the player "catching their footing" as they slide to a stop. (in meters per second).

var physBaseGroundSpeed:float = 5.72		# (def: 5.72) the base maximum speed the player will accelerate to under their own power while on the ground (in meters per second)
var physBaseGroundAccelCoef:float = 10		# (def: 10.0) the base accelerative rate under which the player will aproach the target speed while on the ground. Must be greater than decel value.
var physBaseGroundDecelCoef:float = 6		# (def: 6.00) the base decelerative rate under which the player will stop moving while on the ground.
var physBaseAirSpeed:float = 0.572			# (def: 0.572) the base maximum speed the player will accelerate to under their own power while in the air (in meters per second)
var physBaseAirAccelCoef:float = 2			# (def: 10.0) the base accelerative rate under which the player will aproach the target speed while in the air. Must be greater than decel value.
var physBaseAirDecelCoef:float = 0			# (def: 0.00) the base decelerative rate under which the player will stop moving while in the air.
var physBaseNoclipSpeed:float = 11.4		# (def: 11.4) the base maximum speed the player will accelerate to under their own power while noclipping (in meters per second)
var physBaseNoclipAccelCoef:float = 10		# (def: 10.0) the base accelerative rate under which the player will aproach the target speed while noclipping. Must be greater than decel value.
var physBaseNoclipDecelCoef:float = 6		# (def: 6.00) the base decelerative rate under which the player will stop moving while noclipping.

var physBaseJumpImpulse:float = 5.39		# (def: 5.39) the base impulse force applied to the player during a jump (in meters per second)

var physMaxFloorAng:float = 90			# (def: 47.5) the maximum slope angle the player is able to walk on (in degrees)
var physSlopeSpeedupCoef:float = 1.25		# (def: 1.25) the maximum speedup the player will experience while descending a slope.
var physSlopeSlowdownCoef:float = 0.50		# (def: 0.50) the maximum slowdown the player will experience while ascending a slope.

var physSprintSpeedCoef:float = 1.25		# (def: 1.25) the coefficient of the player's base movespeed applied while the player is sprinting
var physCrouchSpeedCoef:float = 0.65		# (def: 0.65) the coefficient of the player's base movespeed applied while the player is crouching
var physWalkSpeedCoef:float = 0.50			# (def: 0.50) the coefficient of the player's base movespeed applied while the player is walking

### adjustables ###

@export_range(0.10,6.00,0.01,"or_greater") var mouseSens:float = 1.8 # (def: 1.8) mouse sensitivity (equivalent to Source Engine w/ raw input)
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
var inputCamX:Vector3 = Vector3(0,0,0)
var inputCamY:Vector3 = Vector3(0,0,0)
var inputCamZ:Vector3 = Vector3(0,0,0)

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
	# handle player input every frame, but handle the actual physics on the physics tick
	_input_handler()
	return

func _physics_process(delta:float) -> void:
	if inputNoclip:
		_noclip_movement_handler(delta)
	elif _is_on_floor():
		_grounded_movement_handler(delta)
	else:
		_aerial_movement_handler(delta)
	return

#########################################################################################################################################
### PHYSICS PROCESS ###
#########################################################################################################################################

func _grounded_movement_handler(delta:float) -> void:
	%standHull.disabled = false
	%crouchHull.disabled = true
	_grounded_locomotion(delta)
	return

func _aerial_movement_handler(delta:float) -> void:
	%standHull.disabled = false
	%crouchHull.disabled = true
	_aerial_locomotion(delta)
	return

func _noclip_movement_handler(delta:float) -> void:
	%standHull.disabled = true
	%crouchHull.disabled = true
	_noclip_locomotion(delta)
	return

#### GROUNDED ###########################################################################################################################

func _grounded_locomotion(delta:float) -> void:
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0)
	
	# first, determine the direction the player is attempting to move
	var targetDir:Vector3
	targetDir.x = (inputMoveDir2D.z * -inputCamX.z) + (inputMoveDir2D.x * inputCamX.x)
	targetDir.y = 0
	targetDir.z = (inputMoveDir2D.z * inputCamX.x) + (inputMoveDir2D.x * inputCamX.z)
	
	targetDir = targetDir.slide(_get_averaged_floor_normal()).normalized()
	print(targetDir)
	
	# then, determine the speed the player wants to move at
	var targetMoveSpeedCoef:float
	if inputSprint:
		targetMoveSpeedCoef = physSprintSpeedCoef
	elif inputCrouch:
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
		if requiredSpd > 0: # only try to apply an accelerative force to the player if they're not already moving at or faster than their target speed.
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
	
### AERIAL ##############################################################################################################################

func _aerial_locomotion(delta:float) -> void:
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, physBaseGravity)
	
	# first, determine the direction the player is attempting to move
	var targetDir:Vector3
	targetDir.x = (inputMoveDir2D.z * -inputCamX.z) + (inputMoveDir2D.x * inputCamX.x)
	targetDir.y = 0
	targetDir.z = (inputMoveDir2D.z * inputCamX.x) + (inputMoveDir2D.x * inputCamX.z)
	
	# then, determine the speed the player wants to move at (ignoring sprint, since the player cannot sprint in the air)
	var targetMoveSpeedCoef:float
	if inputCrouch:
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
		targetMoveSpeedCoef = physWalkSpeedCoef
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

### TERTIARY FUNCTIONS ##################################################################################################################

func _is_on_floor(override=null) -> bool:
	if override != null:
		return override
	if _get_averaged_floor_normal() != Vector3(0,0,0):
		return true
	else:
		return false

func _get_averaged_floor_normal() -> Vector3:
	var body:PhysicsDirectBodyState3D = PhysicsServer3D.body_get_direct_state(self.get_rid())
	var averageNormal:Vector3 = Vector3(0,0,0)
	var validFloors:int = 0
	for i in body.get_contact_count():
		var contactNormal:Vector3 = body.get_contact_local_normal(i)
		var floorNormal:float = rad_to_deg(contactNormal.angle_to(Vector3(0,1,0)))
		if floorNormal <= physMaxFloorAng:
			validFloors += 1
			averageNormal += contactNormal
	if validFloors == 0:
		return Vector3(0,0,0)
	else:
		return averageNormal.normalized()

#########################################################################################################################################
### PROCESS ###
#########################################################################################################################################

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
	
	#stances
	inputSprint = Input.is_action_pressed("Sprint") and not Input.is_action_pressed("Walk") and not Input.is_action_pressed("Crouch")
	inputCrouch = Input.is_action_pressed("Crouch") and not Input.is_action_pressed("Walk")
	inputWalk = Input.is_action_pressed("Walk")
	
	
	# noclip toggle
	if Input.is_action_just_pressed("Noclip"):
		inputNoclip = not inputNoclip
	
	# camera direction
	inputCamX = %headEyes.global_basis.x
	inputCamY = %headEyes.global_basis.y
	inputCamZ = %headEyes.global_basis.z
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
	max_contacts_reported = 32
	
	%standHull.disabled = false
	%standHull.shape.height = playerHeight
	%standHull.shape.radius = playerWidth / 2
	%standHull.position.x = 0
	%standHull.position.y = playerHeight / 2
	%standHull.position.z = 0
	
	%crouchHull.disabled = true
	%crouchHull.shape.height = playerHeight * playerCrouchHeightCoef
	%crouchHull.shape.radius = playerWidth / 2
	%crouchHull.position.x = 0
	%crouchHull.position.y = (playerHeight * playerCrouchHeightCoef) / 2
	%crouchHull.position.z = 0
	
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
