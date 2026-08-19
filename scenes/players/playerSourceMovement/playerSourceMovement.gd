extends CharacterBody3D

### this player controller is meant to emulate movement from Valve's Source Engine 1. ###
### primarily, the air-strafing and 'surfing' ###

### player dimensions ###

var playerHeight:float = 1.75 				# (def: 1.75) the total height of the player's collision hull (in meters)
var playerWidth:float = 0.50 				# (def: 0.50) the total width of the player's collision hull (in meters)
var playerCrouchHeightCoef:float = 0.60 	# (def: 0.60) the coefficient of the player's total height that the player shrinks to while crouching

var playerHeadEyesHeightCoef:float = 0.94 	# (def: 0.94) the coefficient of the player's total height upon which the camera is positioned
var playerHeadOffsetX:float = 0.00 			# (def: 0.00) the left/right offset from center upon which the camera is positioned (in meters)
var playerHeadOffsetY:float = -0.50 			# (def: 0.00) the up/down offset from center upon which the camera is positioned (in meters)
var playerHeadOffsetZ:float = 2.00 			# (def: 0.00) the forward/backward offset from center upon which the camera is positioned (in meters)

### adjustable settings ###

@export_range(0.10,6.00,0.01,"or_greater") var mouseSens:float = 1.8 # (def: 1.8) mouse sensitivity (equivalent to Source Engine w/ raw input)
@export_range(50,90,1) var cameraFOV:float = 74 # (def: 74) the player viewport's field of view (measured vertically, not horizontally)
@export var autojump:bool = false # (def: false) auto-bhop while true

### player physics ###

var physBaseGroundSpeed:float = 5.72		# (def: 5.715) the base maximum speed the player will accelerate to under their own power while grounded (in meters per second)
var physBaseGroundAccel:float = 57.2		# (def: 57.20) the base accelerative force under which the player will aproach the target speed while grounded
var physBaseGroundDecel:float = 6			# (def: 6.000) the base decelerative force under which the player will stop moving. Don't compare this to physBaseGroundAccel. The math is different.
var physGroundMinDecelSpeed:float = 1.91	# (def: 1.910) the minimum speed at which the player can travel before decelerative forces become stronger than usual. Think of this as the player "catching their footing" as they slide to a stop. (in meters per second).
var physBaseAirSpeed:float = 0.572			# (def: 0.572) the base maximum speed the player will accelerate to under their own power while in the air (in meters per second)
var physBaseAirAccel:float = 3000			# (def: 57.20) the base accelerative force under which the player will aproach the target speed while grounded. This needs to be set to an artificially high value for traditional source-like 'surfing' to work.

var physBaseJumpImpulse:float = 5.39		# (def: 5.390) the base impulse force applied to the player during a jump (in meters per second)

var physNoclipSpeedCoef:float = 3.00		# (def: 3.000) the coefficient of the player's base movespeed applied while the player is noclipping
var physCrouchSpeedCoef:float = 0.65		# (def: 0.650) the coefficient of the player's base movespeed applied while the player is crouching
var physWalkSpeedCoef:float = 0.50			# (def: 0.500) the coefficient of the player's base movespeed applied while the player is walking

### input gathering ###

var inputMoveRaw:Vector3 = Vector3(0,0,0) 	# the player's raw movement inputs
var inputMoveDir2D:Vector3 = Vector3(0,0,0)	# the player's normalized movement inputs (4DoF, WASD only)
var inputMoveDir3D:Vector3 = Vector3(0,0,0)	# the player's normalized movement inputs (6DoF, WASD+up/down)
var inputWalk:bool = false
var inputJump:bool = false
var inputCrouch:bool = false
var inputNoclip:bool = false

### intermediary vars ###

var camDirX:Vector3 = Vector3(0,0,0)
var camDirY:Vector3 = Vector3(0,0,0)
var camDirZ:Vector3 = Vector3(0,0,0)
var targetMoveSpeedCoef:float = 1.0
var targetDir:Vector3 = Vector3(0,0,0)
var targetSpd:float = 0.0
var currentSpd:float = 0.0

func _ready() -> void:
	# given we're emulating Source physics, we need Source gravity, which bizarrely does not match Earth's
	# sv_gravity 800 -> 800Hu/s^2 -> 15.24m/s^2
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 15.24)
	
	# build out the player's nodes according to the specified dimensions
	%standHull.disabled = false
	%standHull.shape.height = playerHeight
	%standHull.shape.radius = playerWidth/2
	%standHull.position.x = 0
	%standHull.position.y = playerHeight/2
	%standHull.position.z = 0
	
	%crouchHull.disabled = true
	%crouchHull.shape.height = playerHeight*playerCrouchHeightCoef
	%crouchHull.shape.radius = playerWidth/2
	%crouchHull.position.x = 0
	%crouchHull.position.y = (playerHeight*playerCrouchHeightCoef)/2
	%crouchHull.position.z = 0
	
	%headYaw.position.x = 0
	%headYaw.position.y = playerHeight*playerHeadEyesHeightCoef
	%headYaw.position.z = 0
	
	%headPitch.position.x = playerHeadOffsetX
	%headPitch.position.y = 0
	%headPitch.position.z = 0
	
	%headEyes.position.x = 0
	%headEyes.position.y = playerHeadOffsetY
	%headEyes.position.z = playerHeadOffsetZ
	
	#capture the mouse so you don't need to click in on startup
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return

func _unhandled_input(event:InputEvent) -> void:
	# handle mouselook, mouse capture/uncapturing
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			%headYaw.rotation_degrees.y += (-event.relative.x * mouseSens)/45.457 # arbitrary number to force mouse sens to match source engine
			%headPitch.rotation_degrees.x += (-event.relative.y * mouseSens)/45.457 # arbitrary number to force mouse sens to match source engine
			%headPitch.rotation_degrees.x = clamp(%headPitch.rotation_degrees.x,-90,90)
			
		if event.is_action_pressed("Escape"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return
	
func _process(delta:float) -> void:	
	# handle player input every frame, handle the actual physics on the physics tick
	# WASD
	var inputFWDBCK = Input.get_axis("Forward","Backward")
	var inputLFTRGT = Input.get_axis("Left","Right")
	var inputUPDOWN = Input.get_axis("Crouch","Jump")
	
	inputMoveRaw = Vector3(inputLFTRGT,inputUPDOWN,inputFWDBCK)
	inputMoveDir2D = Vector3(inputLFTRGT,0,inputFWDBCK).normalized()
	inputMoveDir3D = Vector3(inputLFTRGT,inputUPDOWN,inputFWDBCK).normalized()
	
	# jumping
	if autojump:
		inputJump = Input.is_action_pressed("Jump")
	else:
		inputJump = Input.is_action_just_pressed("Jump")
	
	#stances
	inputCrouch = Input.is_action_pressed("Crouch") and not Input.is_action_pressed("Walk")
	inputWalk = Input.is_action_pressed("Walk")
	
	# noclip toggle
	if Input.is_action_just_pressed("Noclip") and not inputNoclip:
		inputNoclip = true
	elif Input.is_action_just_pressed("Noclip") and inputNoclip:
		inputNoclip = false
	
	# camera direction
	camDirX = %headEyes.global_basis.x
	camDirY = %headEyes.global_basis.y
	camDirZ = %headEyes.global_basis.z
	
	return

func _physics_process(delta:float) -> void:
	if inputNoclip:
		noclip_movement_handler(delta)
	elif is_on_floor():
		grounded_movement_handler(delta)
	else:
		aerial_movement_handler(delta)
	move_and_slide()
	return

func grounded_movement_handler(delta:float) -> void:
	# before we do literally anything, kill the player's vertical velocity, since they are on the ground.
	self.velocity.y = 0
	
	# ..and grab their current speed to be used later
	currentSpd = velocity.length()
	
	# first, determine the direction the player is attempting to move
	targetDir.x = (inputMoveDir2D.z * -camDirX.z) + (inputMoveDir2D.x * camDirX.x)
	targetDir.y = 0
	targetDir.z = (inputMoveDir2D.z * camDirX.x) + (inputMoveDir2D.x * camDirX.z)
	
	# then, determine the speed the player wants to move at
	if inputCrouch:
		targetMoveSpeedCoef = physCrouchSpeedCoef
	elif inputWalk:
		targetMoveSpeedCoef = physWalkSpeedCoef
	else:
		targetMoveSpeedCoef = 1.0
	
	targetSpd = targetMoveSpeedCoef * physBaseGroundSpeed
	
	# since the player is on the ground, next we need to address friction/deceleration
	if currentSpd > 0 and physBaseGroundDecel > 0: # only apply friction if the player is moving and friction is set
		var decelForce:float = max(currentSpd, physGroundMinDecelSpeed) * physBaseGroundDecel * delta # calculate a decelerative force, which scales off the player's current speed
		var newSpd:float = max(currentSpd - decelForce, 0.0) # determine the player's new speed after applying the force to their current speed.
		var newSpdCoef = newSpd/currentSpd   # ]
		velocity.x = velocity.x * newSpdCoef # ]--- apply the new speed
		velocity.z = velocity.z * newSpdCoef # ]
	
	# with everything else complete, now we can finally address acceleration
	if targetDir != Vector3(0,0,0) and physBaseGroundAccel > 0: # only apply acceleration if the player is trying to move and can move.
		var relativeSpd:float = velocity.dot(targetDir) # determine the player's current speed in relation to their desired heading
		var requiredSpd:float = targetSpd - relativeSpd # determine the change in speed required to meet the desired speed
		if requiredSpd > 0: # only try to apply an accerlative force to the player if they're not already moving at or faster than their target speed.
			var baseAccelForce:float = physBaseGroundAccel * min(targetMoveSpeedCoef,1.0) * delta # determine the base accelerative force for this frame
			var accelForce = min(baseAccelForce, requiredSpd) # cap the force if it would cause the player to exceed their target speed
			velocity.x = velocity.x + (targetDir.x * accelForce) # ]
			velocity.z = velocity.z + (targetDir.z * accelForce) # ]--- apply the force to the player along their target heading
			
	# lastly, jumping
	if inputJump:
		self.velocity.y = physBaseJumpImpulse
	
	print("Current Speed: ", currentSpd)
	return

func aerial_movement_handler(delta:float) -> void:
	# grab the player's current speed to be used elsewhere
	currentSpd = velocity.length()
	
	# first, determine the direction the player is attempting to move
	targetDir.x = (inputMoveDir2D.z * -camDirX.z) + (inputMoveDir2D.x * camDirX.x)
	targetDir.y = 0
	targetDir.z = (inputMoveDir2D.z * camDirX.x) + (inputMoveDir2D.x * camDirX.z)
	
	# then, determine the speed the player wants to move at
	if inputCrouch:
		targetMoveSpeedCoef = physCrouchSpeedCoef
	elif inputWalk:
		targetMoveSpeedCoef = physWalkSpeedCoef
	else:
		targetMoveSpeedCoef = 1.0
	
	targetSpd = targetMoveSpeedCoef * physBaseAirSpeed
	
	if targetDir != Vector3(0,0,0) and physBaseAirAccel > 0: # only apply acceleration if the player is trying to move and can move.
		var relativeSpd:float = velocity.dot(targetDir) # determine the player's current speed in relation to their desired heading
		var requiredSpd:float = targetSpd - relativeSpd # determine the change in speed required to meet the desired speed
		if requiredSpd > 0: # only try to apply an accerlative force to the player if they're not already moving at or faster than their target speed.
			var baseAccelForce:float = physBaseAirAccel * min(targetMoveSpeedCoef,1.0) * delta # determine the base accelerative force for this frame
			var accelForce:float = min(baseAccelForce, requiredSpd) # cap the force if it would cause the player to exceed their target speed
			velocity.x = velocity.x + (targetDir.x * accelForce) # ]
			velocity.z = velocity.z + (targetDir.z * accelForce) # ]--- apply the force to the player along their target heading
		
	self.velocity.y = self.velocity.y + (get_gravity().y * delta) # since the player is in the air, you lastly apply gravity
	
	# surfing
	if is_on_wall():
		slope_slide(get_wall_normal())
	return

func noclip_movement_handler(delta:float) -> void:
	currentSpd = velocity.length()
	# first, determine the direction the player is attempting to move
	targetDir.x = (inputMoveDir3D.z * camDirZ.x) + (inputMoveDir3D.x * camDirX.x) + (inputMoveDir3D.y * camDirY.x)
	targetDir.y = (inputMoveDir3D.z * camDirZ.y) + (inputMoveDir3D.x * camDirX.y) + (inputMoveDir3D.y * camDirY.y)
	targetDir.z = (inputMoveDir3D.z * camDirZ.z) + (inputMoveDir3D.x * camDirX.z) + (inputMoveDir3D.y * camDirY.z)
	
	# then, determine the speed the player is attempting to travel at
	if inputWalk:
		targetMoveSpeedCoef = 0.25
	else:
		targetMoveSpeedCoef = 1.0
	
	# next, combine the speed and direction to get a desired velocity vector
	var targetVec = targetDir * targetMoveSpeedCoef * physBaseGroundSpeed * physNoclipSpeedCoef
	
	# finally, apply the target vector to the player's current velocity, shifting it towards the target each tick
	self.velocity.x = lerp(self.velocity.x,targetVec.x,physBaseGroundAccel*delta)
	self.velocity.y = lerp(self.velocity.y,targetVec.y,physBaseGroundAccel*delta)
	self.velocity.z = lerp(self.velocity.z,targetVec.z,physBaseGroundAccel*delta)
	return

func slope_slide(normal:Vector3) -> void:
	# for some reason, the behavior this function provides isn't built into move_and_slide() by default, so we need to do it ourselves.

	# if the player is moving away from the wall, there's nothing to clip, therefore early return.
	if self.velocity.dot(normal) >=0: return
	
	# if the player is moving into the wall, clip the part of their velocity that's pushing into the wall and leave the leftovers. simple.
	# this is the basis of how physically intuitive interactions with slopes works. why doesn't move_and_slide() already do this, Godot?
	var clip:Vector3 = normal*self.velocity.dot(normal)
	self.velocity = self.velocity - clip
	return
