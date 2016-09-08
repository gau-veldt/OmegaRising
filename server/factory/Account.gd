
extends "GOB.gd"


var username
var handle
var email
var emailVfy
var password
var allowed_ip
var characters
var friend=[]
var ignore=[]

# Who is logged onto the Account (non-persistent)
var _session=null
func _set_owner(client=null):
	_session=client
func _is_owner(peer):
	if peer==_session:
		return true
	return false
func logout():
	_session=null

remote func get_attr(peer,key):
	if _is_owner(peer):
		_send(peer,key,self.read(key))
func _send(dest_peer,key,value):
	rpc_id(dest_peer,"attr_is",1,key,value)

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
		if key=="email":
			return [true,email]
		if key=="email_vfy":
			return [true,emailVfy]
		if key=="password":
			return [true,password]
		if key=="characters":
			return [true,characters]
		if key=="allowed_ip":
			return [true,allowed_ip]
		if key=="socials":
			var socials=[]
			for each in friend:
				socials.append("+"+str(each))
			for each in ignore:
				socials.append("-"+str(each))
			return [true,socials]
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
		if key=="email":
			email=val
			return true
		if key=="email_vfy":
			emailVfy=val
			return true
		if key=="password":
			password=val
			return true
		if key=="characters":
			characters=val
			return true
		if key=="allowed_ip":
			allowed_ip=val
			return true
		if key=="socials":
			friend=[]
			ignore=[]
			var ch
			var handle
			for each in val:
				ch=str(each)[0]
				handle=each.right(1)
				if ch=="+":
					friend.append(handle)
				else:
					ignore.append(handle)
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
	write("email","")
	write("email_vfy",false)
	write("password","$")
	write("characters",[])
	write("allowed_ip",[])
	write("socials",[])

func _spawn():
	_spawn_Account()
