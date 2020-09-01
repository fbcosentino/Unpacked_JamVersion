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

# NarratorTrigger objects are used to fire dialogs/events without
# any user decision, but instead by just entering the area:
#
# - StopAfter is used to make the NarratorTrigger usable only a limited
#   number of times. If StopAfter=1, it is a single-shot trigger. If
#   StopAfter=3, it will fire 3 times, etc. Once it was fired StopAfter times,
#   it disables itself. Keep StopAfter=0 to fire all times.
#
# - Conversely, OnlyShowAfter keeps the NarratorTrigger silent until it
#   was fired a number of times. Unlike StopAfter, before OnlyShowAfter the
#   trigger is not disabled (as it needs to be enabled to trigger and
#   count), it is just silent (it triggers, counts, but doesn't fire. In
#   other words, it is just lurking the player).
#   So if OnlyShowAfter = 1, it will ignore the first hit and fire at the
#   second. If OnlyShowAfter=5, it will ignore first 5 hits and show the 6th,
#   etc. Keep OnlyShowAfter=0 to fire since the first hit.
#
#  You can combine StopAfter and OnlyShowAfter to make sequences. Examples:
#      Trigger A has StopAfter=1 and OnlyShowAfter=0
#      Trigger B has StopAfter=1 and OnlyShowAfter=1
#      When first entering the area, Trigger A happens (only). Leaving and
#      entering the area again, Trigger B happens (only). Leaving and
#      entering a third time, nothing happens.
#
#      Trigger A has StopAfter=0 and OnlyShowAfter=10, with area slightly
#      larger (via extra CollisionShape) so it is touched first
#      Trigger B has StopAfter=0 and OnlyShowAfter=0
#      When entering the area, Trigger B always fires. If this is the 10th
#      time (or later), adds the Trigger A dialogue first (e.g. "Are you
#      not tired of me already?") and then proceeds to Trigger B normally
#
# - Firing a trigger causes a sequence of messages to show, turning the page
#   by pressing the Interact button (E / X). Each page/message is one item
#   in the Texts array. Each item is a BB Code string, so you can use any
#   features available in BB Code RichTextlabel. Currently supported:
#       - Normal text
#       - Italic via [i]text here[/i]
#       - Bold via [b]text here[/b] (use with care, font is also bigger)
#       - Colors via [color=#html_hex_code]text here[/color]
#
# - If Freeze = false, the player controls will be disabled until the
#   dialogue sequence is fully dismissed. Otherwise, the player is allowed
#   to continue playing while the message is there. Firing new triggers in
#   this state will put them on hold, and will be shown when this one is
#   dismissed. While testing the game it became obvious this is a bad
#   experience as the text will not be in sync with the events, and therefore
#   Freeze must be set to true unless you know very well what you are doing.
#
# - It fires an optional animation from an AnimationPlayer if
#   TriggerAnimationPlayer is set.
#   Keep in mind the animation and the text are asynchronous and therefore
#   the player will most likely see the animation before reading anything.
#   If you need the animation to play only in the middle of the dialogue
#   sequence, split it into 2 triggers and place the animation in the second.
#   Default animation name is Action but it can be set in TriggerAnimationName
#   If more that one animation is used in the same AnimationPlayer, all
#   animations must modify the same objects, so that firing only one of
#   the animations is enough to set all objects to their correct state.
#   In other words: if you have one animation in which the raven throws a
#   fruit, all other animations in that AnimationPlayer must put back the
#   fruit to the correct position it would be when that animation is fired.
#   Reset animation state *MUST* be defined in an animation called "Reset"
#   and this name cannot be changed. This must eb set to Autoplay.
#   This is important: all changes done in any of the animations 
#   fired by NarratorTriggers must be undone/redone by calling
#   one of the other animations. This is used when a player rolls the game 
#   back by restoring to a previous checkpoint or loading a game state. 
#   In this case, the last fired animation in that checkpoint will be fired
#   and moved to its last frame, and this must be enough to restore all the
#   game state involving those NarratorTriggers. If the trigger was never 
#   fired, the "Reset" animation is used.
#   If you want to have more than one triggered animation in the same
#   AnimationPlayer, you need one NarratorTrigger for each.
#   In the siplest case of only one animation, you will have:
#       - One "Reset" animation in autoplay with the default state prior to
#         the trigger (rolls back the action, or plays idle state)
#       - One "Action" animation which happens when the trigger is fired
#   Looping animations work normally (e.g. raven eating)
#   AnimationTrackMode must be configured to match the type of animation:
#       - DoNotTrack is used when there is no AnimationPlayer set
#       - IsCompleted is used when the animation is one-shot
#       - IsPlaying is used when the animation loops
#
# - If the PushPlayer vector is set, the player will be pushed towards that
#   direction IN THE LOCAL COORDINATE FRAME OF THE TRIGGER. In other words,
#   rotating the trigger also rotates this. The practice used in Unpacked
#   is to always keep this vector in the X axis, and using local space
#   (shortcut hotkey "T") to rotate the trigger, so the player will be pushed
#   across red arrow. A value of [100, 0, 0] has good result in Unpacked.
#
# - An extra action can be performed in parallel, set in ExtraAction
#   Currently only one is implemented: starting the clock. When starting a
#   new game by default the clock is not running. It will only start after
#   hitting this trigger. Hitting it again will reset the clock, so if this
#   is not desired, use it in a trigger with StopAfter=1
#
# - Setting Enabled=false will disable this trigger. This is implemented
#   to be used in animations in AnimationPlayers controlled by other triggers,
#   so a trigger only becomes active (or is deactivated) due to other events
#   in the game. E.g.:
#       The message suggesting to look around is deactivated if the player
#       moves the rock first in the pit
#       The sniffing trigger in the raven is only activated after the dialogue
#
# It comes with a 2m cylinder collision shape, but if larger area is
# needed, DO NOT SCALE the NarratorTrigger as it yields weird results
# Instead add more collision shapes to it, as all will contribute


# === Configuration variables for this trigger

# Should the player controls be disabled during this dialog?
export(bool) var Freeze = false

# Array of messages
export(Array, String, MULTILINE) var Texts = [""]

# Should we stop showing this dialog after a few times? 0 = disable
export(int) var StopAfter = 0

# Should we only show this dialog after a few times? 0 = disable
export(int) var OnlyShowAfter = 0

# If an AnimationPlayer is set, we play an animation when triggered
export(NodePath) var TriggerAnimationPlayer = ""
var TriggerAnimationPlayerNode = null

# Default animation name is "Action" but it can be changed here
export(String) var TriggerAnimationName = "Action"

# Method for tracking the TriggerAnimationPlayer in saved state
export(Utils.ANIM_TRACK_MODE) var AnimationTrackMode = Utils.ANIM_TRACK_MODE.DoNotTrack

# Push the player towards any particular direction (in local space)?
export(Vector3) var PushPlayer = Vector3(0,0,0)

# Any special extra action to be performed?
export(Utils.NARRATOR_ACTION) var ExtraAction = Utils.NARRATOR_ACTION.None

# General Enable used by animations to disable a trigger
export(bool) var Enabled = true

func _ready():
	# The correct practice is usually to emit signals from children
	# And handle them on parent. But on this particular case, we want
	# to have a general purpose trigger object which can be cloned at
	# will connecting itself to parent passing self as argument
	# Standard body_entered signal does not track sender, so adhering
	# to standard practice does not justify the extra effort on this case
	
	# (As a cool side effect, this will also avoid triggering if
	# the player starts the level inside the trigger)
	
	# Wait an idle frame to make sure the Main object is properly set
	yield(get_tree(), "idle_frame")
	
	# Get the Main object
	var main = get_node("/root/Main")
	
	# Connect the body_entered signal passing self as extra argument
	# (the reason we are doing all of this)
	var _error = connect("body_entered", main, "_on_NarratorTrigger", [self])
	
	# The game must be aware of the animations this trigger uses, so when
	# loading a game or restoring a checkpoint the correct state (or reset
	# state) can be properly fired, as well as save files be assembled.
	# Therefore, triggers notify Manager when they use any animations
	# so they can be tracked
	# To simplify tracking, the AnimationPlayer nodepath and the animation
	# name are combined into one string, used as key in a dictionary

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
