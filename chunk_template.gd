extends Spatial

onready var grid=get_node("Grid")

var chunk_x=0
var chunk_y=0
var tileSet=preload("user://gfx/terrain_tiles.png")
var mixSet=preload("user://gfx/mix_tiles.png")
var btmMap=null
var topMap=null
var mixMap=null
var heightMap=null

func _ready():
	btmMap=load("user://world/overworld/btm_%d_%d.png" % [chunk_x,chunk_y])
	topMap=load("user://world/overworld/top_%d_%d.png" % [chunk_x,chunk_y])
	mixMap=load("user://world/overworld/mix_%d_%d.png" % [chunk_x,chunk_y])
	heightMap=load("user://world/overworld/height_%d_%d.png" % [chunk_x,chunk_y])
	var theMat=grid.get('material/0')
	var mat=theMat.duplicate()
	grid.set('material/0',mat)
	mat.set_shader_param('heightMap',heightMap)
	mat.set_shader_param('vScale',.05)
	mat.set_shader_param('btmTilemap',btmMap)
	mat.set_shader_param('topTilemap',topMap)
	mat.set_shader_param('mixTilemap',mixMap)
	mat.set_shader_param('tileset',tileSet)
	mat.set_shader_param('mixset',mixSet)
	mat.set_shader_param('tileSize',128)
	mat.set_shader_param('tilesetWidth',1024)
	mat.set_shader_param('tilesetHeight',1024)

