extends Spatial

export var base="res://"
export var rings=6 setget ringSet
export var far=100
var radius
var diameter
var csize
var map={}
var loadQueue=[]

var tileSet=load("user://gfx/terrain_tiles.png")
var mixSet=load("user://gfx/mix_tiles.png")

var center=Vector2(0,0)

func ringSet(newRingCount):
	rings=max(newRingCount,1)
	diameter=1+(2*rings)
	radius=diameter/2.0
	csize=far/(radius-1.0)
	if csize>int(csize): csize+=1
	csize=int(csize)
	recenter(center)

func moveTo(v3):
	var xCell=int(v3.x/csize)
	var zCell=int(v3.z/csize)
	recenter(Vector2(xCell,zCell))

var fs=File.new()
func load_chunk(fnm,v2,x,z):
	#print("load chunk: (",x,",",z,")")
	var ob
	if fs.file_exists(fnm):
		ob=load(fnm).instance()
		ob.tileSet=tileSet
		ob.mixSet=mixSet
	else:
		ob=Spatial.new()
	map[v2]=ob
	if ob.get_translation()==Vector3(0,0,0):
		ob.set_translation(Vector3(x*csize,0,z*csize))
	ob.set_name("cell (%d,%d)"%[x,z])
	add_child(ob)

signal LoadBegin()
signal LoadProgress(cur,last)
signal LoadEnd()
func recenter(newCtr):
	if int(center.x)!=int(newCtr.x) or int(center.y)!=int(newCtr.y):
		center=newCtr
		var xL=center.x-rings
		var xH=center.x+rings
		var zL=center.y-rings
		var zH=center.y+rings
		var v2=Vector2(0,0)
		var cells=map.keys()
		for v2 in cells:
			if v2.x<xL or v2.x>xH or v2.y<zL or v2.y>zH:
				if map[v2]!=null:
					map[v2].queue_free()
				map.erase(v2)
		var ob
		var fc
		var fnm
		var fs=File.new()
		for x in range(xL,1+xH):
			for z in range(zL,1+zH):
				v2.x=x
				v2.y=z
				if !map.has(v2):
					#fnm=base.plus_file("chunk_%d_%d.scn"%[x,z])
					fnm=base.plus_file("chunk_%d_%d.scn"%[0,0])
					loadQueue.append([fnm,v2,x,z])
		loadCycle=true
		loadHead=0
		loadTail=loadQueue.size()
		emit_signal("LoadBegin",loadTail)
		set_process(true)

var loadCycle=false
var loadHead=0
var loadTail=0
var nextChk
func _process(delta):
	if loadCycle:
		for slice in range(min(1,loadTail-loadHead)):
			nextChk=loadQueue[0]
			load_chunk(nextChk[0],nextChk[1],nextChk[2],nextChk[3])
			loadQueue.pop_front()
			emit_signal("LoadProgress",loadHead,loadTail-1)
			loadHead+=1
		if loadHead>=loadTail:
			loadCycle=false
			set_process(false)
			loadHead=0
			loadTail=0
			emit_signal("LoadEnd")

func _ready():
	var cur=center
	center=center+Vector2(1,1)
	recenter(cur)

