
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

#
# Character creation/management
#
signal charlist_changed(list)
onready var cg=get_node("/root/Peer/Tabber/Character Template")
remote func get_cg_template(peer):
	var cgProc="cg_template"
	if _is_owner(peer):
		var cg_template=cg.getTemplate()
		if server.has_hook(cgProc):
			var cg_copy={}
			for each in cg_template.keys():
				cg_copy[each]=cg_template[each]
			server.call_hook(cgProc,[self,cg_copy])
			cg_template=cg_copy
		_send_var(peer,cgProc,cg_template)
func _send_var(dest_peer,rpc_name,data):
	rpc_id(dest_peer,rpc_name,1,data)

# Character creation request
remote func request_character_create(peer,form):
	var rc=[-1,"Not imeplemented"]
	var cg_template=cg.getTemplate()
	var cgProc="request_character_create"
	if _is_owner(peer):
		var cg_template=cg.getTemplate()
		if charform_validate(form,cg_template,rc):
			rc[0]=0
			rc[1]="Successful."
			if server.has_hook(cgProc):
				server.call_hook(cgProc,[self,form,cg_template,rc])
			if rc[0]==0:	# no validation error from external script
				# check for duplicate name
				var dupe=false
				var charIdx=persist.get_gob_index('Player')
				var chars=charIdx.get_children()
				var name
				for char in chars:
					if char.read('name')==form['CharacterName']:
						dupe=true
						break
				if dupe:
					rc[0]=6
					rc[1]="Duplicate character name %s" % form['CharacterName']
				else:
					var PC=persist.spawn('Player')
					var props=PC.read('props')
					for key in form:
						if key!="CharacterName":
							props[key]=form[key]
						else:
							PC.write('name',form[key])
					PC.write('props',props)
					var pcList=read('characters')
					pcList[form['CharacterName']]=PC.get_name()
					write('characters',pcList)
					emit_signal("charlist_changed",pcList)
					rpc_id(peer,"charlist_changed",1,pcList)

		rpc_id(peer,"creation_response",1,rc)

# Account attribute access
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
	write("characters",{})
	write("allowed_ip",[])
	write("socials",[])

func _spawn():
	_spawn_Account()

func charform_validate(form,template,rc):
	var attrs=template['Attributes']
	for attr in form:
		# ensure form has no extraneous attributes
		if !attrs.has(attr):
			rc[0]=1
			rc[1]="Illegal attribute %s" % attr
			return false
	for attr in attrs:
		# ensure form has all required attributes before attempting to process
		if !form.has(attr):
			rc[0]=2
			rc[1]="Attribute %s missing" % attr
			return false
	for attr in attrs:
		var def=attrs[attr]
		var type=def['type']
		if type in ['String']:
			if form[attr]=="":
				rc[0]=3
				rc[1]="Attribute %s is blank" % attr
				return false
		if type in ["IntRange","FloatRange"]:
			var num
			if type=="IntRange":
				num=int(form[attr])
			else:
				num=float(form[attr])
			if num<def['min'] or num>def['max']:
				rc[0]=4
				rc[1]="Attribute %s: %d not in range [%s,%s]" % [attr,num,def['min'],def['max']]
				return false
		if type in ["ChooseOne","ChooseMulti"]:
			var flist
			if type=="ChooseOne":
				flist=[form[attr]]
			else:
				flist=form[attr]
			var valid=[]
			for opt in def['options']:
				if opt.has('always'):
					valid.append(opt['always'])
				if opt.has('when'):
					var passed=true
					for each in opt['when']:
						var test=false
						var tAttr=each['attr']
						var tOpt=each['option']
						var tInv=each['not']
						test=(form[tAttr]==tOpt)
						if tInv: test=(!test)
						passed=passed and test
					if opt.has('Include'):
						for incl in opt['Include']:
							if passed:
								valid.append(incl)
					if opt.has('Exclude'):
						for excl in opt['Exclude']:
							if !passed:
								valid.append(excl)
			for opt in flist:
				if not opt in valid:
					rc[0]=5
					rc[1]="Attribute %s has invalid option %s" % [attr,opt]
					return false
	return true

