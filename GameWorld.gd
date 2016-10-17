extends Spatial

onready var client=get_node("/root/Peer")
onready var userAcct=client.userAcct
onready var world=get_node("world")
onready var env=world.get_environment()
onready var doll=get_node("Dolly")
onready var cam=doll.get_node("camera")
onready var lpw=get_node("LoadBar")
onready var hair=get_node("Cross")

var main_menu=null
var terrain=null
var target=null setget changeTarget
var who=""

func changeTarget(tgt):
	target=tgt
	set_process(target!=null)
	if (tgt!=null):
		client.candy.hide()
		cam.make_current()
	else:
		client.candy.show()
		client.candy.regain()

func loadProg(cur,final):
	var pct=int(100*float(cur)/float(final))
	lpw.set_min(0)
	lpw.set_max(final)
	lpw.set_val(cur)
	lpw.show()
	if pct>=85:
		client.change_bgm(null)

var sky
func _ready():
	lpw.hide()
	hair.hide()
	terrain=load("res://TerrainScroller.scn").instance()
	sky=load("user://gfx/sky.png")
	client.connect("Quitting",self,"onQuitting")
	terrain.hide()
	terrain.connect("LoadProgress",self,"loadProg")
	add_child(terrain)
	yield(terrain,"LoadEnd")
	terrain.disconnect("LoadProgress",self,"loadProg")
	lpw.hide()
	terrain.show()
	env.set_background(Environment.BG_TEXTURE)
	env.set_background_param(Environment.BG_PARAM_TEXTURE,sky)
	doll.set_translation(Vector3(8,0,0))
	cam.set_translation(Vector3(0,1.5,0))
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
var mgrab=false
func _fixed_process(delta):
	var drot=doll.get_rotation()
	var crot=cam.get_rotation()
	if Input.is_action_pressed("char_frwd"):
		doll.translate(Vector3(0,0,-1)*(speed['frwd/run']*delta))
	if Input.is_action_pressed("char_rvrs"):
		doll.translate(Vector3(0,0,1)*(speed['rvrs']*delta))
	if Input.is_action_pressed("char_slide_L"):
		doll.translate(Vector3(-1,0,0)*(speed['slide']*delta))
	if Input.is_action_pressed("char_slide_R"):
		doll.translate(Vector3(1,0,0)*(speed['slide']*delta))
	if mgrab:
		var spd=Input.get_mouse_speed()
		if old_spd!=null:
			if old_spd!=spd:
				crot.x-=(spd.y*speed['damp']*delta)
				crot.x=max(crot.x,-PI/2)
				crot.x=min(crot.x,PI/2)
				drot.y-=(spd.x*speed['damp']*delta)
		old_spd=spd
	cam.set_rotation(crot)
	doll.set_rotation(drot)

	if Input.is_action_just_pressed("ui_grab_mouse"):
		mgrab=!mgrab
		if mgrab:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			hair.show()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			hair.hide()

func _process(delta):
	terrain.moveTo(doll.get_translation())

func logoutCharacter():
	mgrab=false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hair.hide()
	changeTarget(false)
	hide()
	if main_menu!=null:
		main_menu.set_hidden(false)
		client.candy.set_hidden(false)
	queue_free()

func onQuitting():
	mgrab=false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hair.hide()
	changeTarget(false)
	hide()
	queue_free()

