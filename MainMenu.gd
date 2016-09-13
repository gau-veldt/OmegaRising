extends Panel

onready var client=get_node("/root/Peer")
onready var userAcct=client.userAcct
onready var menus=get_node("menu")
onready var btnPlay=menus.get_node("Play")
onready var selChar=menus.get_node("CharacterSelect")
onready var btnCreate=menus.get_node("Create")
onready var btnAccount=menus.get_node("Account")
onready var btnQuit=menus.get_node("Quit")

var useChar=""

func _process(delta):
	btnPlay.set_disabled(useChar=="")

func onQuit():
	client.fade_quit()

func _ready():
	btnQuit.connect("pressed",self,"onQuit")
	set_process(true)
