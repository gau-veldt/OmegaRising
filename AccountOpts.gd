extends TabContainer

onready var client=get_node("/root/Peer")
onready var userAcct=client.userAcct

func onQuitting():
	hide()
	queue_free()

func _ready():
	client.connect("Quitting",self,"onQuitting")
	set_process(true)

func _process(delta):
	if client.test_cancel():
		client.ui_sound('error')
		hide()
		queue_free()

