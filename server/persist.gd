
extends Node

var base="user://persist/default/"
onready var scrib=get_node("/root/Peer/game_scripts")

func set_base(dir):
	dir=dir.replace("/","")
	base="user://persist/%s/" % dir
	validate_dir()

func validate_dir():
	var d=Directory.new()
	if !d.dir_exists("user://persist"):
		d.make_dir("user://persist")
	if !d.dir_exists(base):
		d.make_dir(base)

var guid_state={
	'serial':0,
	'mac':[int(65535.0*randf()),int(65535.0*randf()),int(65535.0*randf())]
}
func generate_guid():
	#
	#  GUID generation for game objects
	#  NB: This is not an RFC-compliant guid generator!
	#
	var uid="%X%X-%X-F" % guid_state['mac']
	var now=OS.get_datetime()
	var ms=OS.get_ticks_msec()
	var yr=now['year']-1582
	var jd=((now['month']-1)*31)+now['day']
	uid+="%03X-%04X-" % [yr,0x8000+(jd*24)+now['hour']]
	var msm=now['minute']
	msm=(msm*60)+now['second']
	msm=(msm*1000)+ms
	uid+="%06X" % msm
	uid+="%06X" % guid_state['serial']
	guid_state['serial']=(guid_state['serial']+1)%0x1000000
	return uid

const _uuid_char="0123456789ABCDEF-"
func is_uuid(raw):
	var test=str(raw).to_upper()
	if test.length()==36:
		var parts=test.split("-")
		if parts.size()==5:
			if  parts[0].length()==8 and \
				parts[1].length()==4 and \
				parts[2].length()==4 and \
				parts[3].length()==4 and \
				parts[4].length()==12:
				for ch in test:
					if not ch in _uuid_char:
						return false
				return true
	return false

# game object factories
var factory={}
func populate_factory():
	#
	#  Load factory index of game objects
	#  which live in res://factory.  These get generated
	#  at runtime via factory["class"].instance()
	#
	var dir=Directory.new()
	if !dir.dir_exists("res://factory"):
		dir.make_dir("res://factory")
	if dir.open("res://factory")!=null:
		dir.list_dir_begin()
		var file=dir.get_next()
		var ext
		var base
		while file!="":
			ext=file.right(file.length()-5)
			if ext.to_lower()==".tscn":
				base=file.left(file.length()-5)
				factory[base]=load("res://factory/%s" % file)
			file=dir.get_next()

#
#  Object indexing
#
onready var index=get_node("/root/Peer/index")
var index_bytype={}
var index_all={}
func index_object(uuid,type,ob):
	if !(type in index_bytype):
		var node=Node.new()
		node.set_name(type)
		index.add_child(node)
		index_bytype[type]=node
	index_bytype[type].add_child(ob)
	index_all[uuid]=ob

func get_gob_index(type):
	if !(type in index_bytype):
		var node=Node.new()
		node.set_name(type)
		index.add_child(node)
		index_bytype[type]=node
	return index_bytype[type]

# cache of modified objects to write on next call to save()
var modified={}
func flag_unsaved(ob):
	modified[ob.get_name()]=ob

func spawn(type):
	var uuid=generate_guid()
	var ob=factory[type].instance()
	ob.set_name(uuid)
	index_object(uuid,type,ob)
	ob._spawn()							# set default values
	modified[uuid]=ob
	return ob

func reconstitute(uuid):
	if index_all.has(uuid):
		return index_all[uuid]
	var file=File.new()
	var err=file.open(base.plus_file(uuid),File.READ)
	if err==OK:
		var type=file.get_line()
		var raw=file.get_line()
		var data={}
		data.parse_json(raw)
		var ob=factory[type].instance()
		# do NOT call ob._spawn() here
		ob.set_name(uuid)
		index_object(uuid,type,ob)
		ob.deserialize(data)
		modified.erase(uuid)
		return ob
	return null

func load_all():
	# used once when server starts
	# (loads all objects)
	var file=File.new()
	var dir=Directory.new()
	var name
	# workaround since dir.open("user://") is bugged
	var workaround=OS.get_data_dir().plus_file(base.right(7))
	if dir.open(workaround)!=null:
		dir.list_dir_begin()
		name=dir.get_next()
		while name!="":
			if name.length()==36:
				reconstitute(name)
			name=dir.get_next()

func save():
	# persists all changed objects
	var info={}
	var ob
	var data
	var out=File.new()
	for each in modified:
		ob=modified[each]
		data=ob.serialize()
		out.open(base.plus_file(each),File.WRITE)
		out.store_line(ob.type())
		out.store_line(data)
		out.close()
	modified.clear()

func nuke(ob):
	# completely removes object from both disk and memory
	var type=ob.type()
	var uuid=ob.get_name()
	if modified.has(uuid):
		modified.erase(uuid)
	if index_all.has(uuid):
		index_all.erase(uuid)
	var dir=Directory.new()
	dir.remove(base.plus_file(uuid))
	# bytype index entry deleted when child removed from parent
	ob.queue_free()

var scripts={}
func loadGameScripts():
	var loc=(OS.get_data_dir()).plus_file("scripts")
	var dir=Directory.new()
	if !dir.dir_exists(loc):
		dir.make_dir(loc)
	dir.open(loc)
	var file
	var ext
	var base
	var scr
	dir.list_dir_begin()
	file=dir.get_next()
	while file!="":
		ext=file.right(file.length()-3)
		if ext.to_lower()==".gd":
			base=file.left(file.length()-3)
			if base.length()>0:
				scr=load(loc.plus_file(file))
				if scr!=null:
					var ob=Node.new()
					ob.set_name(file)
					ob.set_script(scr)
					scripts[base]=ob
					scrib.add_child(ob)
		file=dir.get_next()

func _ready():
	populate_factory()
	validate_dir()
	load_all()
	loadGameScripts()

func str2vec(orgstr):
	var lstr=str(orgstr).right(1)
	lstr=lstr.left(lstr.length()-1)
	lstr=lstr.replace(" ","")
	var lary=[]
	for each in lstr.split(","):
		lary.append(float(each))
	var len=lary.size()
	if (len==1): return lary[0]
	if (len==2): return Vector2(lary[0],lary[1])
	if (len==3): return Vector3(lary[0],lary[1],lary[2])
	return lary
