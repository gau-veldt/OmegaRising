extends Spatial

onready var client=get_node("/root/Peer")
onready var userAcct=client.userAcct
onready var world=get_node("world")
onready var env=world.get_environment()
onready var cam=get_node("camera")

var main_menu=null
var terrain=null
var target=null setget changeTarget
var who=""

func changeTarget(tgt):
	target=tgt
	set_process(target!=null)
	if (tgt!=null):
		cam.make_current()
	else:
		client.candy.regain()

var sky
func _ready():
	terrain=load("res://TerrainScroller.scn").instance()
	sky=load("user://gfx/sky.png")
	env.set_background(Environment.BG_TEXTURE)
	env.set_background_param(Environment.BG_PARAM_TEXTURE,sky)
	add_child(terrain)
	cam.set_translation(Vector3(8,1.5,0))
	client.connect("Quitting",self,"onQuitting")
	client.change_bgm("bgm/world_test")
	set_fixed_process(true)
	set_process(true)

var speed={
	'frwd/walk'	:	1.5,
	'frwd/run'	:	2.5,
	'rvrs'		:	.75,
	'slide'		:	1.5,
	'damp'		:	.03
}

var old_spd=null
func _fixed_process(delta):
	var rot=cam.get_rotation()
	cam.set_rotation(Vector3(0,rot.y,rot.z))
	if Input.is_action_pressed("char_frwd"):
		cam.translate(Vector3(0,0,-1)*(speed['frwd/run']*delta))
	if Input.is_action_pressed("char_rvrs"):
		cam.translate(Vector3(0,0,1)*(speed['rvrs']*delta))
	if Input.is_action_pressed("char_slide_L"):
		cam.translate(Vector3(-1,0,0)*(speed['slide']*delta))
	if Input.is_action_pressed("char_slide_R"):
		cam.translate(Vector3(1,0,0)*(speed['slide']*delta))
	var spd=Input.get_mouse_speed()
	if old_spd!=null:
		if old_spd!=spd:
			#rot.x+=(spd.y*speed['damp']*delta)
			#rot.x=max(rot.x,-90)
			#rot.x=min(rot.x,90)
			rot.y+=(spd.x*speed['damp']*delta)
	old_spd=spd
	cam.set_rotation(rot)

func _process(delta):
	terrain.moveTo(cam.get_translation())

func logoutCharacter():
	changeTarget(false)
	hide()
	if main_menu!=null:
		main_menu.set_hidden(false)
		client.candy.set_hidden(false)
	queue_free()

func onQuitting():
	changeTarget(false)
	hide()
	queue_free()

