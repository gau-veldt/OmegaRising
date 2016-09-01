
extends Node

signal MOTD(msg)

remote func hello(id):
	if id==1:
		print("Got server hello.")
	else:
		print("Invalid hello from peer %d." % id)

remote func motd(id,msg):
	if id==1:
		emit_signal("MOTD",msg)
	else:
		print("Invalid MOTD from peer %d." % id)

func _ready():
	pass

