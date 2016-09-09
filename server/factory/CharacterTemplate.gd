
extends "GOB.gd"

var template

func type():
	return "CharacterTemplate"

func on_read(key):
	return _read_CharacterTemplate(key)

func on_write(key,value):
	return _write_CharacterTemplate(key,value)

func _read_CharacterTemplate(key):
	var baserc=_read_GOB(key)
	if !baserc[0]:
		if key=="template":
			return [true,template]
		return [false,null]
	else:
		return baserc

func _write_CharacterTemplate(key,val):
	var baserc=_write_GOB(key,val)
	if !baserc:
		if key=="template":
			template=val
			return true
		return false
	else:
		return baserc

func _ready():
	pass

func _spawn_CharacterTemplate():
	_spawn_GOB()
	write("template",{})

func _spawn():
	_spawn_CharacterTemplate()

