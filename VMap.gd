#
#  Virtual TileMap
#
#  Allows very large maps on disk to be paged as quadrants
#  Centered on the player, neighbouring quadrants are loaded
#  to result in 3x3 (9) quadrants loaded at all times.
#
#  As player moves the quadrant centered on the player will be
#  at the edge of the 3x3 loaded map.  The loaded quadrant
#  indices will be adjusted so the player quadrant is once
#  again in the center.  Any now-unloaded cells will then
#  load and quadrants outside the 3x3 quadrant zone are
#  then unloaded.
#

extends Node2D

export(int) var tileSize=32
export(int) var quadrantSize=128

signal LoadQuadrant(quadName,layer,tileMap,curVMap)

var mapLayer=[]
var center=null

onready var lightNode=get_node("Lighting")
onready var tileSet=load("res://gfx/tiles.tres")

func getLights():
	# returns list of light nodes on map
	return lightNode.get_children()

func enableLights(bEnable):
	lightNode.set_hidden(not bEnable)

func setLightLevel(amt):
	for light in getLights():
		light.lightMax=amt

func setLightVariance(amt):
	for light in getLights():
		light.lightVariance=amt

func setLightColor(clr):
	for light in getLights():
		light.set_color(clr)

func create_segment(sx,sy,sName):
	# creates quadrant section tilemap
	var tm=TileMap.new()
	tm.set_name(sName)
	var sz=Vector2(tileSize,tileSize)
	tm.set_cell_size(sz)
	tm.set_tileset(tileSet)
	var pos=Vector2(sx*tileSize*quadrantSize,sy*tileSize*quadrantSize)
	tm.set_pos(pos)
	return tm

func recenter(cx,cy):
	var qx=int(cx/(tileSize*quadrantSize))
	var qy=int(cy/(tileSize*quadrantSize))
	var newCenter=Vector2(qx,qy)
	var cvt
	if newCenter!=center:

		# unload quadrants more than 1 away
		var nodes
		var nodequad=[]
		var dist
		for i in range(4):
			nodes=mapLayer[i].get_children()
			for each in nodes:
				nodequad.clear()
				for val in each.get_name().split(","):
					cvt=("0x"+val).hex_to_int()
					if cvt>=524288:
						cvt-=1048576
					nodequad.append(cvt)
				dist=int(max(abs(nodequad[1]-newCenter.x),abs(nodequad[0]-newCenter.y)))
				if dist>1:
					mapLayer[i].remove_child(each)
					each.free()

		# emit LoadQuadrant signal for each unloaded quadrant
		var nx
		var ny
		var qx
		var qy
		var nstr
		for row in range(-1,2):
			ny=row+newCenter.y
			qy=ny
			if ny<0:
				ny+=1048576
			for col in range(-1,2):
				nx=col+newCenter.x
				qx=nx
				if nx<0:
					nx+=1048576
				nstr="%05x,%05x" % [ny,nx]
				if !has_node("lower/%s" % nstr):
					# create tilemap nodes for
					# new parts of the map
					var tm
					for lyr in range(4):
						tm=create_segment(qx,qy,nstr)
						mapLayer[lyr].add_child(tm)
						tm.set_owner(self)
						emit_signal("LoadQuadrant",nstr,lyr,tm,self)

		# shift map center
		center=newCenter

func _ready():
	mapLayer=[]
	mapLayer.append(get_node("lower"))
	mapLayer.append(get_node("mid_lower"))
	mapLayer.append(get_node("mid_upper"))
	mapLayer.append(get_node("upper"))
	center=null

	# this will load up the map in quadrants:
	# fffff,fffff 00000,fffff 00001,fffff
	# fffff,00000 00000,00000 00001,00000
	# fffff,00001 00000,00001 00001,00001
	#recenter(0,0)

	setLightVariance(.11)
