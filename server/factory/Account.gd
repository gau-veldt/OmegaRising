
extends "GOB.gd"

var username
var handle
var password
var characters

func type():
	return "Account"

func on_read(key):
	return _read_Account(key)

func on_write(key,value):
	return _write_Account(key,value)

func _read_Account(key):
	var baserc=_read_GOB(key)
	if !baserc[0]:
		if key=="username":
			return [true,username]
		if key=="handle":
			return [true,handle]
		if key=="password":
			return [true,password]
		if key=="characters":
			return [true,characters]
		return [false,null]
	else:
		return baserc

func _write_Account(key,val):
	var baserc=_write_GOB(key,val)
	if !baserc:
		if key=="username":
			username=val
			return true
		if key=="handle":
			handle=val
			return true
		if key=="password":
			password=val
			return true
		if key=="characters":
			characters=val
			return true
		return false
	else:
		return baserc

func _ready():
	pass

func _spawn_Account():
	_spawn_GOB()
	write("username","nobody")
	write("handle","nil")
	write("password","$")
	write("characters",[])

func _spawn():
	_spawn_Account()
