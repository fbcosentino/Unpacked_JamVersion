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

# Game over screen on defeat
# Waits for the player to press the interact button, then
# fires the FadeOut animation and loads Intro scene

# This scene does not change anything in Manager
# Intro screen is entered exactly as it would be if
# the player had clicked "Quit to Main Menu"
# This means the player can still load back the last checkpoint
# (If the game over screen is reached there is probably not 
# much the player can do anyway, better off loading a previous
# state or starting a new game, but the possiblity exists...)

# Holds the fade-in and fade-out animations
onready var Anims = get_node("AnimationPlayer")

func _input(event):
	# The only thing we do here is go back to title screen (Intro)
	if Input.is_action_just_pressed("interact"):
		# Play the animation
		Anims.play("FadeOut")
		# Wait for it to finish
		yield(Anims, "animation_finished")
		# Back to Intro
		get_tree().change_scene("res://Scenes/Intro.tscn")
		
