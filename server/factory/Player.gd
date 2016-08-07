
extends "Mob.gd"

func type():
	return "Player"

func on_read(key):
	return _read_Player(key)

func on_write(key,value):
	return _write_Player(key,value)

func _read_Player(key):
	var baserc=_read_Mob(key)
	if !baserc[0]:
		return [false,null]
	else:
		return baserc

func _write_Player(key,val):
	var baserc=_write_Mob(key,val)
	if !baserc:
		return false
	else:
		return baserc

func _ready():
	pass

func _spawn_Player():
	_spawn_Mob()

func _spawn():
	_spawn_Player()
