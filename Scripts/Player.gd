#===============================================================================
#             SOURCE CODE FOR 'UNPACKED' - GODOW WILD JAM VERSION                 
#
#                       madparrot.itch.io/unpacked-gwj
#                 github.com/fbcosentino/Unpacked_JamVersion
#-------------------------------------------------------------------------------
#
#                *** FOR LICENSE CHECK THE "LICENSE" FILE ***
#      (But in short: code and nodes are free to use at will, art is not.)
#
# This file is part of the source code for the game Unpacked - Jam Version
# Unpacked is a game initially developed for the Godot Wild Jam - #24, and
# development continued afterwards as a normal full version game. The jam 
# version is open source and released on github.
# This version is made using Godot Engine v3.2.2.stable.official
#
# All the game code, scene files, images, models and music were designed by:
#   Fernando Cosentino
#   github.com/fbcosentino
#
# Except the GWJ art which refers to:
#   Godot Wild Jame
#   godotwildjam.com
#
#===============================================================================


extends KinematicBody

# Signals
signal Interact # When user presses E or gamepad X
signal Tracking    # When user presses Q or gamepad Y
signal LookDown(enabled) # When approaching/leaving an abyss


# Configuration variables
export var PlayerRotationSpeed = 1.0
export var PlayerMoveSpeed = 1.0
export var PlayerJumpSpeed = 1.0
export var PlayerJumpDecay = 0.05
export var PlayerRunSpeed = 1.6
export var CoyoteTime = 0.1
export var SlopeAdjustSpeed = 5.0
export var PushSpeed = 10.0

# Gravity is negative to be semantic in the math
export var PlayerGravity = -9.8

# Node instances
onready var AnimPlayer = get_node("Skeleton/AnimationPlayer")
onready var SFXJump = get_node("SFXJump/AnimationPlayer")
onready var SFXStep = get_node("SFXStep/AnimationPlayer")

# Physics variables
var jump_velocity = Vector3()

var is_running = false       # True when gamepad full forward or keyboard shift
var is_jumping = false       # True after hitting jump key and still on air  
var is_double_jumping = false # True when second jump was already activated
var is_ending_jump = false   # True while JumpOut animation plays
var is_on_floor_coyote = 0.0        # delta counter used for coyote jump

var PushedVector = Vector3(0,0,0)  # If the player is currently being pushed
									# Damps automatically

# Variable used by Main to adjust the camera angle
# based on the floor slope angle
var SlopeAngle = 0.0 # radians


# ----------------
# Animation state machine
enum ANIM_STATE {
	Idle,
	Walk,
	Run,
	Jump
}
var CurrentAnimationState = ANIM_STATE.Idle

# List of collision bodies in front of the player
# Used to know when there is some sort of abyss to look at
var ListOfFrontGround = []
# Size of ListOfFrontGround, updated when ListOfFrontGround changes
var FrontGroundCount = 0

func _input(_event):
	# Process simple trigger keys, such as E to interact
	# This does not process normal input involved in physics
	# (such as walking, jumping etc)
	# Those are processed in _physics_process() instead
	
	# If we are loading a level, abort
	if Manager.LoadingLevel:
		return
	
	# If game is paused, abort
	if Manager.IsPaused:
		return
	
	# Is user pressing button to interact?
	if Input.is_action_just_pressed("interact"):
		emit_signal("Interact")

	# Is user pressing button to track?
	if Input.is_action_just_pressed("tracking"):
		emit_signal("Tracking")


func _physics_process(delta):
	# Process normal user input

	# If we are loading a level, abort
	if Manager.LoadingLevel:
		return

	# If game is paused, abort
	if Manager.IsPaused:
		return

	
	# Each axis variable holds a float in the range [-1.0, +1.0]
	# Vertical axis moves player forth and back
	# Horizontal axis turns player around
	var axis_v
	var axis_h
	# Holds a boolean if user pressed a jump button
	var btn_jump
	# Nolds a boolean if player is pressing shift to run
	var btn_run
	
	is_running = false
	
	# Only process input if not frozen by a dialog
	if not Manager.InDialogFreeze:

		# === Gamepad axes ===
		if Manager.HasGamepad:
			# Axis 0 is left stick, horizontal - positive pointing right
			axis_h = Input.get_joy_axis(Manager.GamepadID, 0)
			# Axis 1 is left stick, vertical - positive pointing down
			# We use -axis here since we want positive meaning forward
			axis_v = -Input.get_joy_axis(Manager.GamepadID, 1)
			# Full forward is running
			if abs(axis_v) >= 0.95:
				is_running = true
	
		# === Keyboard axes ===
		# Keyboard intentionally overwrites gamepad values
		# H
		axis_h = 0.0
		if Input.is_action_pressed("move_left"):
			axis_h = -1.0
		if Input.is_action_pressed("move_right"):
			axis_h = 1.0
			
		# Currently overriding get_joy_axis as a quick fix
		# to be reviewed in the future
		if Input.is_action_pressed("joy_left"):
			axis_h = -0.5*PlayerRunSpeed
		if Input.is_action_pressed("joy_right"):
			axis_h = 0.5*PlayerRunSpeed
			
		# V
		axis_v = 0.0
		if Input.is_action_pressed("move_up"):
			axis_v = -1.0
		if Input.is_action_pressed("move_down"):
			axis_v = 1.0

		if Input.is_action_pressed("joy_up"):
			axis_v = -1.0*PlayerRunSpeed
		if Input.is_action_pressed("joy_down"):
			axis_v = 1.0*PlayerRunSpeed
			
		# === Jump button
		btn_jump = Input.is_action_just_pressed("move_jump")
		
		# === Run button
		btn_run = Input.is_action_pressed("move_run")
		
		
	# If frozen, reset values
	else:
		axis_v = 0.0
		axis_h = 0.0
		btn_jump = false
		btn_run = false
	
		

	
	# === Jump
	# Jump is allowed when player is either
	#   - On floor (obviously)
	#   - On air during a jump, has the Double Jump skill, and dit not use yet
	var will_jump
	
	# Intention to jump may or may not be fulfilled
	# will_jump will store the success state of a jump
	will_jump = false
	
	# Coyote jump: if touching floor, is_on_floor_coyote is reset
	if is_on_floor():
		is_on_floor_coyote = CoyoteTime
	# Otherwise it is a downcounter
	else:
		is_on_floor_coyote -= delta
		if is_on_floor_coyote < 0:
			is_on_floor_coyote = 0.0
		
		
	# We can actually jump if downcounter did not reach zero
	if is_on_floor_coyote > 0:
		# If jump key just pressed, we succeed
		if btn_jump:
			will_jump = true
		
		# Otherwise, if was jumping, will be no more
		elif is_jumping:
			jump_velocity = Vector3()
			is_jumping = false
			is_double_jumping = false
			is_ending_jump = true
			AnimPlayer.play("JumpOut")
			SFXStep.stop(true)
			SFXStep.play("Fire")
	
	# Otherwise, we are on air (falling or mid-jump)
	else:
		# Double jump?
		if is_jumping and Manager.HasDoubleJump and (not is_double_jumping) and btn_jump:
			is_double_jumping = true
			will_jump = true
		
		# Otherwise damp jump
		else:
			jump_velocity = jump_velocity.linear_interpolate(Vector3(0.0, 0.0, 0.0), PlayerJumpDecay)

	
	# If any of the combinations above causes a successful jump:
	if will_jump:
		# We counteract gravity by subtracting it
		jump_velocity = Vector3(0.0, -PlayerGravity + PlayerJumpSpeed, 0.0)
		is_jumping = true
		is_ending_jump = false
		SetAnimation(ANIM_STATE.Jump)
		# we are not on floor anymore (otherwise cancels jump)
		is_on_floor_coyote = 0.0 
		# Play sound
		SFXJump.stop(true)
		SFXJump.play("Fire")
	
	# === Run
	var move_speed = PlayerMoveSpeed
	# If running, multiply speed by running factor
	if btn_run:
		is_running = true
		move_speed *= PlayerRunSpeed
		

	# === Apply movement:
	
	# Turn player around
	rotate_y(-axis_h * PlayerRotationSpeed * delta)
	
	# Move forth and back
	# Convert direction to global space:
	# Project a global point in front of player, and subtract player position
	var move_dir = (to_global(Vector3(0.0, 0.0, axis_v)) - global_transform.origin) * move_speed
	# Add jump
	move_dir += jump_velocity
	
	# Add gravity
	# PlayerGravity is correct for falling but is too high to walk on floor
	# We don't need much of a gravity when on floor, but if we don't have any
	# the player looses contact with floor bringing gravity back and 
	# causing is_on_floor() to flicker. So when on floor, we use smaller
	# gravity value just to avoid loosing touch
	# Notice the coyote time also applies to gravity here
	# This reduces flickering in the IFs
	if is_on_floor_coyote > 0:
		move_dir += Vector3(0.0, PlayerGravity*0.05, 0.0)
	else:
		move_dir += Vector3(0.0, PlayerGravity, 0.0)
		
	# Player being pushed towards a direction?
	# This happens when firing a trigger with PushPlayer set
	if PushedVector.length() > 0.0:
		# We cannot allow PushSpeed*delta > 1.0, or the pushed_vector will
		# increase instead of damping, so we clip to 1.0 (instant move)
		var push_fac = min(1.0, PushSpeed * delta)
		# Move a fraction of the vector
		move_dir += PushedVector * push_fac
		# Damp the remaining vector
		PushedVector *= (1.0 - push_fac)
		
	# Move player and slide on floor
	var result_dir = move_and_slide( move_dir, Vector3(0, 1.0, 0), true, 4, PI/4, false) # linear velocity, up vector, stop on slopes, slide steps, floor angle, infinite inertia
	
	
	# === Rotation illusions
	# Mildly rotate the player based on velocity
	
	# If player not on floor, apply pitch based on vertical jump/fall
	if not is_on_floor():
		# Limit the velocity we react to
		var clamped_v = clamp(move_dir.y, -10, +10)
		# Apply pitch to model
		rotation.x = clamped_v * 0.052 # radians, max here will be 0.52rad ~= 30 deg
	
	# If player is on floor, reset pitch
	else:
		if result_dir.length() > 0:
			# From the resulting moving direction, calculate the sin of the slope angle
			var sin_slope = Vector3(0.0, 1.0, 0.0).dot(result_dir.normalized()) 
			# And the actual angle - clamp to slope angle
			var slope_angle = clamp(asin(sin_slope), -0.35, 0.35)

			# Pitch the player to match the slope
			SlopeAngle = lerp_angle(rotation.x, slope_angle, delta*SlopeAdjustSpeed)
			rotation.x = SlopeAngle
		else:
			rotation.x = 0.0
	
	
	# === Animation
	
	# Set proper animation - if involved in jumping
	if not (is_jumping or is_ending_jump):
		# If moving:
		if (axis_v != 0):
			# If running, run
			if is_running:
				SetAnimation(ANIM_STATE.Run)
			# Otherwise, walk
			else:
				SetAnimation(ANIM_STATE.Walk)
		# If not moving, just relax around
		else:
			SetAnimation(ANIM_STATE.Idle)
			



func SetAnimation(state):
	# Requests a particular animation state in the state machine
	# If this causes a change of state, calls the corresponding animation
	# Otherwise just let current animation play
	# Exception is jump - always play animation
	
	# If it's a jump, always play animation
	if (state == ANIM_STATE.Jump):
		AnimPlayer.play("JumpIn")
	
	# Otherwise only take action if there is a change
	elif (state != CurrentAnimationState):
		match state:
			ANIM_STATE.Idle:
				AnimPlayer.play("Idle")
			ANIM_STATE.Walk:
				AnimPlayer.play("Walk")
			ANIM_STATE.Run:
				AnimPlayer.play("Run")
				
	# Set CurrentAnimationState as this state
	CurrentAnimationState = state
		


func _on_AnimationPlayer_animation_finished(anim_name):
	# When "JumpOut" animation is completed, go back to normal animations
	if anim_name == "JumpOut":
		is_ending_jump = false
		SetAnimation(ANIM_STATE.Idle)


# The Abyss Detector is a collision detection in front of the player used to
# find out when there is an empty space ahead and below, which means the
# player is facing some sort of abyss. When this happens, we move the camera
# a bit up so the player can face the abyss (and also gives the abyss a
# chance to look back into the player's soul, as they say)

func _on_FrontAbyss_body_entered(body):
	# This method is called when an object enters the abyss detector
	# if it is the only object present, we are no longer facing an abyss
	
	# Add this body to the list of bodies at front-ground
	ListOfFrontGround.append(body)
	
	# Is this the first item in the list?
	if FrontGroundCount == 0:
		# We have ground now, no need to look down
		emit_signal("LookDown", false)
	
	# Update count
	FrontGroundCount = ListOfFrontGround.size()
	
	

func _on_FrontAbyss_body_exited(body):
	# This method is called when an object leaves the abyss detector
	# if it was the last one, we are now facing an abyss
	
	# Remove this body to the list of bodies at front-ground
	ListOfFrontGround.erase(body)

	# Was this the last item in the list?
	if FrontGroundCount == 1:
		# No more ground, look down!
		emit_signal("LookDown", true)

	# Update count
	FrontGroundCount = ListOfFrontGround.size()



