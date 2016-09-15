extends Node2D

onready var view3d=get_node("View3D/Panner")
onready var cube=view3d.get_node("TestCube")

var angle=0.0
var rpm=10
func _process(delta):
	angle+=360.0*delta*(float(rpm)/60.0)
	if angle>360.0: angle -=360
	if angle<0.0: angle+=360
	cube.set_rotation_deg(Vector3(0,angle,0))

func _ready():
	set_process(true)
