
extends "GOB.gd"

var username
var password
var characters

func type():
	return "Account"

func on_read(key):
	if key=="username":
		return [true,username]
	if key=="password":
		return [true,password]
	if key=="characters":
		return [true,characters]
	return [false,null]

func on_write(key,val):
	if key=="username":
		username=val
		return true
	if key=="password":
		password=val
		return true
	if key=="characters":
		characters=val
		return true
	return false

func _ready():
	write("username","nobody")
	write("password","$")
	write("characters",[])
