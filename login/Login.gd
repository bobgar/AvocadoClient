extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here.
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _on_Button_pressed():
	var userName = $UserNameInput.text
	var password = $PasswordInput.text
	Utils._log("Username: %s" % userName)
	Utils._log("Password: %s" % password)
	pass # Replace with function body.
