
extends Node

remote func hello(id):
	if id==1:
		print("Got server hello.")
	else:
		print("Invalid hello from peer %d." % id)

func _ready():
	pass

