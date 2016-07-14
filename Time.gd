
extends Label

# member variables here, example:
# var a=2
# var b="textvar"

onready var anim=get_node("../../DayNightCycle")


func _process(delta):
	if anim!=null:
		var tm=anim.get_pos()
		var hrs=int(tm/60.0)
		tm-=(60.0*float(hrs))
		var mins=int(tm)
		var tim=""
		if hrs<10: tim+="0"
		tim+=str(hrs)+":"
		if mins<10: tim+="0"
		tim+=str(mins)
		#var secs=int(60.0*(tm-float(mins)))
		#if secs<10: tim+="0"
		#tim+="."+str(secs)
		set_text(tim)
	else:
		set_text("99:99")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)


