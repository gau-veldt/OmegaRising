extends Spatial

onready var grid=get_node("Grid")

var worldDir="user://world/overworld"

var chunk_x=0
var chunk_y=0
var tileSet=null
var mixSet=null
var btmMap=null
var topMap=null
var mixMap=null
var heightMap=null
var hScale=0.05
var cellsize=19

func rgb2h(pix):
	return hScale*(-32768+int(pix.r*255)+256*int(pix.g*255))

func _ready():
	btmMap=load(worldDir.plus_file("btm_%d_%d.png" % [chunk_x,chunk_y]))
	topMap=load(worldDir.plus_file("top_%d_%d.png" % [chunk_x,chunk_y]))
	mixMap=load(worldDir.plus_file("mix_%d_%d.png" % [chunk_x,chunk_y]))
	heightMap=load(worldDir.plus_file("height_%d_%d.png" % [chunk_x,chunk_y]))
	var theMat=grid.get('material/0')
	var mat=theMat.duplicate()
	grid.set_name("del")
	grid.queue_free()
	grid=MeshInstance.new()
	grid.set_name("Grid")
	add_child(grid)

	mat.set_shader_param('cellCount',cellsize)
	mat.set_shader_param('vScale',hScale)
	mat.set_shader_param('btmTilemap',btmMap)
	mat.set_shader_param('topTilemap',topMap)
	mat.set_shader_param('mixTilemap',mixMap)
	mat.set_shader_param('tileset',tileSet)
	mat.set_shader_param('mixset',mixSet)
	mat.set_shader_param('tileSize',128)
	mat.set_shader_param('tilesetWidth',1024)
	mat.set_shader_param('tilesetHeight',1024)

	var sf=SurfaceTool.new()
	var hImg=heightMap.get_data().resized(1+cellsize,1+cellsize)
	sf.begin(VS.PRIMITIVE_TRIANGLES)
	sf.add_smooth_group(true)

	var offs=-(cellsize/2.0)
	var vx
	var vz
	var ht=[0,0,0,0]

	for row in range(cellsize):
		vz=offs+row
		for col in range(cellsize):
			vx=offs+col
			ht[0]=rgb2h(hImg.get_pixel(col  ,row  )) # A 0,0
			ht[1]=rgb2h(hImg.get_pixel(col+1,row  )) # B 1,0
			ht[2]=rgb2h(hImg.get_pixel(col  ,row+1)) # C 0,1
			ht[3]=rgb2h(hImg.get_pixel(col+1,row+1)) # D 1,1
			# /\ CAB
			sf.add_uv(Vector2(0,1))
			sf.add_vertex(Vector3(vx  ,ht[2],vz+1))
			sf.add_uv(Vector2(0,0))
			sf.add_vertex(Vector3(vx  ,ht[0],vz  ))
			sf.add_uv(Vector2(1,0))
			sf.add_vertex(Vector3(vx+1,ht[1],vz  ))
			# /\ BDC
			sf.add_uv(Vector2(1,0))
			sf.add_vertex(Vector3(vx+1,ht[1],vz  ))
			sf.add_uv(Vector2(1,1))
			sf.add_vertex(Vector3(vx+1,ht[3],vz+1))
			sf.add_uv(Vector2(0,1))
			sf.add_vertex(Vector3(vx  ,ht[2],vz+1))

	sf.generate_normals()
	sf.index()
	var mesh=sf.commit()
	sf.clear()
	grid.set_mesh(mesh)
	grid.set('material/0',mat)

