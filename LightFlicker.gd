
extends Light2D

# member variables here, example:
# var a=2
# var b="textvar"

export(float) var lightMax=0.75
export(float) var lightVariance=0.15
var twinklePhase=0.5 setget changePhase
var twinkleTime=1.5  setget changeSpeed
var lightLevel=0.0

onready var anim=get_node("Flicker")

func _process(delta):
	set_energy(max(0.0,lightMax-(lightLevel*lightVariance)))

func changePhase(amt):
	twinklePhase=amt
	if anim != null:
		anim.seek(twinklePhase,true)

func changeSpeed(dur):
	twinkleTime=dur
	if anim != null:
		anim.set_speed(1.0/twinkleTime)

func randSpeed():
	changeSpeed(1.5+rand_range(-0.75,0.75))
	
func randPhase():
	changePhase(rand_range(0,19)*0.05)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	randSpeed()
	randPhase()

	set_process(true)

