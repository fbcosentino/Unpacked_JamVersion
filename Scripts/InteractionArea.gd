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


extends Area

# InteractionArea objects are used to fire dialogs/events with
# user decision by pressing the Interaction button (E / X) while touching it
# It is very similar to NarratorTrigger (read that one first)
# Additionally, it can add a skill to the player
# (currently only double jump is implemented, as sniffing is ON by default)
# It comes with a 2m cylinder collision shape, but if larger area is
# needed, DO NOT SCALE the InteractionArea as it yields weird results
# Instead add more collision shapes to it, as all will contribute


# Interactions has a type variable indicating the extra behaviour
# Currently only Dialog type is defined, but there will be more later

# Signals parent if this interaction area is available or not
# Available means it will trigger when pressing E
signal Available(sender, state)

# ==============================================================================
# CONFIGURATION VARIABLES

export(Utils.TRIGGER_TYPE) var Type = Utils.TRIGGER_TYPE.Dialog

# Array of messages
export(Array, String, MULTILINE) var Texts = [""]

# Should we stop showing this dialog after a few times? 0 = disable
export(int) var StopAfter = 0

# Should we only show this dialog after a few times? 0 = disable
export(int) var OnlyShowAfter = 0

# Should the player controls be disabled during this dialog?
export(bool) var Freeze = false

# If an AnimationPlayer is set, we play an animation when triggered
export(NodePath) var TriggerAnimationPlayer = ""
var TriggerAnimationPlayerNode = null

# Default animation name is "Action" but it can be changed here
export(String) var TriggerAnimationName = "Action"

# Method for tracking the TriggerAnimationPlayer in saved state
export(Utils.ANIM_TRACK_MODE) var AnimationTrackMode = Utils.ANIM_TRACK_MODE.DoNotTrack

# Does this trigger give any skills?
export(Utils.SKILLS) var GiveSkill = Utils.SKILLS.None

# General Enable used by animations to disable a trigger
export(bool) var Enabled = true


# "E" icon mesh
onready var Hint = get_node("Hint")

# Called when the node enters the scene tree for the first time.
func _ready():
	Hint.hide()
	
	# The correct practice is usually to emit signals from children
	# and connect them to parent. But on this particular case, we want
	# to have a general purpose trigger object which can be cloned at
	# will, connecting itself to parent passing self as argument
	# This significantly reduces the work and avoids situations in which
	# script recompilation disconnects signals in the levels, so adhering
	# to standard practice does not justify the extra effort on this case
	
	# (As a cool side effect, this will also avoid triggering if
	# the player starts the level inside the trigger)
	
	# Wait an idle frame to make sure the Main object is properly set
	yield(get_tree(), "idle_frame")
	
	# Get the Main object
	var main = get_node("/root/Main")
	
	# Connect "Available" signal to Main object
	var _error = connect("Available", main, "_on_InteractionArea_Available")
	
	# If we have an animation set, ask Manager to track it
	if TriggerAnimationPlayer != "":
		# Get the node into a variable
		TriggerAnimationPlayerNode = get_node(TriggerAnimationPlayer)
		
		# Do we need to track it?
		if AnimationTrackMode != Utils.ANIM_TRACK_MODE.DoNotTrack:
			# Get absolute path to this AnimationPlayer as string
			var abs_path = str(TriggerAnimationPlayerNode.get_path())
			# Assemble the item string. It is a single string to facilitate
			# checking for its existence in the array
			var item_key = Utils.JoinPlayerAndAnimation(abs_path, TriggerAnimationName)
			# Ask manager to track it
			Manager.TrackAnimation(item_key)
			# Make the relevant connection
			if AnimationTrackMode == Utils.ANIM_TRACK_MODE.IsCompleted:
				_error = TriggerAnimationPlayerNode.connect("animation_finished",Manager,"_on_TrackedAnimation_TrackState",[abs_path, Utils.ANIM_TRACK_MODE.IsCompleted])
			elif AnimationTrackMode == Utils.ANIM_TRACK_MODE.IsPlaying:
				_error = TriggerAnimationPlayerNode.connect("animation_started",Manager,"_on_TrackedAnimation_TrackState",[abs_path, Utils.ANIM_TRACK_MODE.IsPlaying])

	
func UpdateVisibility():
	pass
	# Updates object visibility to reflect counter
	# If too soon (dialog not ready yet):
	#   Hides only hint
	# If too late (dialog already fired enough)
	#   Hides everything
	var count = 0
	# If this interaction area is in saved state, get the counter
	if (Manager.CurrentLevel in Manager.FiredDialogs):
		if name in Manager.FiredDialogs[Manager.CurrentLevel]:
			count = Manager.FiredDialogs[Manager.CurrentLevel][name]
	# Otherwise defaults to 0

	# Did we trigger this enough already?
	if ((StopAfter > 0) and (count >= StopAfter)):
		# Too late, hide hint
		Hint.hide()
		
	# Did we not trigger enough?
	elif (count < OnlyShowAfter):
		# Too soon, hide hint
		Hint.hide()
	
	else:
		# Otherwise, hint should be visible:
		Hint.show()


func _on_InteractionArea_area_entered(area):
	# If the collision is not with player, abort
	if area.name != "PlayerInteraction":
		return

	# Ignore disabled triggers
	if not Enabled:
		return
	
	UpdateVisibility()
	emit_signal("Available", self, true)


func _on_InteractionArea_area_exited(area):
	# If the collision is not with player, abort
	if area.name != "PlayerInteraction":
		return
	
	Hint.hide()
	emit_signal("Available", self, false)
