extends Node

var template={}
var attrs={}
var signals={}

var _peer=null
func set_peer(id):
	_peer=id

func read(key):
	var signame="notify_%s" % key
	if !signals.has(signame):
		add_user_signal(signame)
		signals[signame]=true
	rpc_id(1,"get_attr",_peer,key)
remote func attr_is(from,key,value):
	if from==1:
		var signame="notify_%s" % key
		attrs[key]=value
		emit_signal(signame)

func get_cg_template():
	var signame="cg_template"
	if !signals.has(signame):
		add_user_signal(signame)
		signals[signame]=true
	rpc_id(1,"get_cg_template",_peer)
remote func cg_template(from,cg_form):
	if from==1:
		template=cg_form
		emit_signal("cg_template")

var create_status
remote func request_creation(form):
	var signame="creation_response"
	if !signals.has(signame):
		add_user_signal(signame)
		signals[signame]=true
	rpc_id(1,"request_character_create",_peer,form)
remote func creation_response(from,rc):
	if from==1:
		create_status=rc
		emit_signal("creation_response")

func _ready():
	pass

var charList=null
signal CharacterListChanged(list)
func get_character_list():
	if charList==null:
		self.read("characters")
		yield(self,"notify_characters")
		charList=attrs['characters']
	emit_signal("CharacterListChanged",charList)
remote func charlist_changed(from,newList):
	if from==1:
		charList=newList
		attrs['characters']=newList
		emit_signal("CharacterListChanged",charList)
