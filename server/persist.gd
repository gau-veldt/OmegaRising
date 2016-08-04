
extends Node

var base="user://persist/default/"

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

# cache of modified objects to write on next call to save()
var modified={}

func flag_unsaved(ob):
	modified(ob.get_name())=ob

func spawn(type):
	var uuid=generate_guid()
	var ob=factory[type].instance()
	ob.set_name(uuid)
	modified[uuid]=ob
	return ob

func reconstitute(uuid):
	var file=File.new()
	var err=file.open(base.plus_file(uuid))
	if err==OK:
		var type=file.get_line()
		var data={}.parse_json(file.get_line())
		var ob=factory[type].instance()
		ob.set_name(uuid)
		ob.deserialize(data)
		return ob
	return null

func save():
	# persists all changed objects
	var info={}
	var ob
	var data
	var out=File.new()
	for each in modified:
		ob=modified[each]
		data=ob.serialize()
		out.open(base.plus_file(each).File.WRITE)
		out.store_line(ob.type())
		out.store_line(data)
		out.close()
	modified.clear()

func _ready():
	populate_factory()
	validate_dir()
