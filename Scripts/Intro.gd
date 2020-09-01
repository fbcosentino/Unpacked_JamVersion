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

# Flags to track if mouse is petting the fox
var is_petting = false
var in_pet_transition = false

# Animation objects
onready var FadeAnimation = get_node("Interface/FadeRect/AnimationPlayer")
onready var FadeRect = get_node("Interface/FadeRect")
onready var PetAnimation = get_node("Stage/Fox/AnimationPlayer")
onready var HandAnimation = get_node("Stage/Hand/AnimationPlayer")

# Called when the node enters the scene tree for the first time.
func _ready():

	# Reset all visibilities to start state
	get_node("Interface/Credits").hide()
	get_node("Interface/Menu/BtnLoad").disabled = true
	FadeRect.show()
	

	# Play FadeIn animation
	FadeAnimation.play("FadeIn")
	
	# Wait animation to finish
	yield(FadeAnimation, "animation_finished")


	# Check if we have a saved state to activate the load button
	var file = File.new()
	if file.file_exists("user://save01.dat"):
		get_node("Interface/Menu/BtnLoad").disabled = false

	# Put focus on first button
	get_node("Interface/Menu/BtnNewGame").grab_focus()
	




func _on_BtnNewGame_pressed():
	# Creates a new game
	Manager.NewGame()
	StartGame()


func _on_BtnLoad_pressed():
	# Loads a game from a saved file
	
	Manager.LoadGameFromFile()
	StartGame()


func _on_BtnCredits_pressed():
	# "Credits" button: show Credits screen and puts focus on "Back" button
	get_node("Interface/Credits").show()
	get_node("Interface/Credits/BtnBack").grab_focus()


func _on_BtnQuit_pressed():
	get_tree().quit()


func _on_Credits_BtnBack_pressed():
	# "Back" button on Credits screen: 
	# hide Credits screen and puts focus back on "Credits" button
	get_node("Interface/Credits").hide()
	get_node("Interface/Menu/BtnCredits").grab_focus()
	
	
	
	
func StartGame():
	# The logic below is only valid from the intro menu
	# Starting a new game from a current running game uses
	# uses a restart logic in Main script
	
	# Play FadeOut animation
	FadeAnimation.play("FadeOut")
	
	# Wait animation to finish
	yield(FadeAnimation, "animation_finished")
	
	# Load main scene
	var _error = get_tree().change_scene("res://Scenes/Main.tscn")




func _on_Pet_input_event(_camera, event, _click_position, _click_normal, _shape_idx):
	# Triggered when mouse interacts with the fox head
	
	# Check if this is a left mouse button
	if (event is InputEventMouseButton) and (event.button_index == BUTTON_LEFT):
		# If user clicked, start petting
		if event.pressed:
			# Set flags
			is_petting = true
			in_pet_transition = true
			# Play pet start transition
			PetAnimation.play("StartPet")
			# Wait for it to finish
			yield(PetAnimation, "animation_finished")
			# Play hand animation
			HandAnimation.play("Pet")
			# If the mouse was quick and released during the transition,
			# we can stop already
			if not is_petting:
				# stop hand
				HandAnimation.play("Rest")
				# Play the stop transition
				PetAnimation.play("StopPet")
				# No need to wait, a click during StopPet interrupts it
			# Clear the transition flag
			in_pet_transition = false
		
		# If user released, stop petting
		# We check is_petting since the pressed = true may have happened
		# somewhere else and just releasing it here
		elif is_petting:
			# Clear flag
			is_petting = false
			# If not in a transition (that is, if holding down for a while)
			if not in_pet_transition:
				# stop hand
				HandAnimation.stop()
				
				# play the stop transition
				PetAnimation.play("StopPet")
	


func _on_PetAnimation_animation_finished(anim_name):
	# If StopPet animation is finished, start idle animation
	# Since this is the only handled case, there is no need for
	# AnimationTree
	if anim_name == "StopPet":
		PetAnimation.play("Idle")


func _on_Pet_mouse_exited():
	# If player is petting and mouse leaves, counts as release
	if is_petting:
		# Clear flag
		is_petting = false
		# If not in a transition (that is, if holding down for a while)
		if not in_pet_transition:
			# stop hand
			HandAnimation.stop()
			
			# play the stop transition
			PetAnimation.play("StopPet")
