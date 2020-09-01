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


extends Spatial

# Game over screen when game is successfully completed
# Displays time statistics and waits for interaction key,
# leaving back to main menu


# Holds the fade-in and fade-out animations
onready var Anims = get_node("AnimationPlayer")

# Holds label for progress
onready var ProgressLabel = get_node("Interface/ProgressLabel")

func _ready():
	# Shows progress
	var progress = Manager.GameTime / (Manager.GameMaximumTime*60.0) 
	# Build text
	var text = "[color=#333333]You completed the game in [/color][b][color=#000000]"
	text += str(round(progress*100.0))
	text += "[/color][/b][color=#333333]% of available time.\n([/color]"
	text += "[b][color=#000000]"
	text += str(round(Manager.GameTime / 60.0))
	text += "[/color][/b][color=#333333] out of [/color][b][color=#000000]"
	text += str(round(Manager.GameMaximumTime))
	text += "[/color][/b][color=#333333] minutes.)[/color]"
	# Show text
	ProgressLabel.bbcode_text = text

func _input(event):
	# The only thing we do here is go back to title screen (Intro)
	if Input.is_action_just_pressed("interact"):
		# Play the animation
		Anims.play("FadeOut")
		# Wait for it to finish
		yield(Anims, "animation_finished")
		# Back to Intro
		get_tree().change_scene("res://Scenes/Intro.tscn")
		
