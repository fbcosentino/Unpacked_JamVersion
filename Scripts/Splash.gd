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


extends Control

# Splash screen shown at game startup
# Only interaction here is pressing space bar to skip to menu

# There is no need to setup anything on scene load or ready
# The AnimationPlayer is set to auto-play


func _on_AnimationPlayer_animation_finished(_anim_name):
	# We have only one animation in this AnimationPlayer
	# When finished we call the intro menu
	var _error = get_tree().change_scene("res://Scenes/Intro.tscn")

func _input(event):
	# If event is a key just pressed
	if (event is InputEventKey) and (event.pressed) and (not event.echo):
		# If SPACE BAR, skip animations
		if event.scancode == KEY_SPACE:
			var _error = get_tree().change_scene("res://Scenes/Intro.tscn")
